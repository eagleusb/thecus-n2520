/*
 * USB Attached SCSI
 * Note that this is not the same as the USB Mass Storage driver
 *
 * Copyright Matthew Wilcox for Intel Corp, 2010
 * Copyright Sarah Sharp for Intel Corp, 2010
 *
 * Distributed under the terms of the GNU GPL, version two.
 */

#include <linux/version.h>
#include <linux/blkdev.h>
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/module.h>
#include <linux/usb.h>
#if (LINUX_VERSION_CODE > KERNEL_VERSION(2,6,34))
#include <linux/usb/hcd.h>
#else
#include "../core/hcd.h"
#endif
#include <linux/usb_usual.h>
#include <linux/usb/uas.h>

#include <scsi/scsi.h>
#include <scsi/scsi_dbg.h>
#include <scsi/scsi_cmnd.h>
#include <scsi/scsi_device.h>
#include <scsi/scsi_host.h>
#include <scsi/scsi_tcq.h>

#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,37))
#define USB_SC_SCSI	US_SC_SCSI
#define USB_PR_BULK	US_PR_BULK
#define USB_PR_UAS	US_PR_UAS
#endif

//#define CONFIG_USB_UAS_ENABLE_TASK_MANAGEMENT 1

/*
 * The r00-r01c specs define this version of the SENSE IU data structure.
 * It's still in use by several different firmware releases.
 */
struct sense_iu_r01 {
	__u8 iu_id;
	__u8 rsvd1;
	__be16 tag;
	__be16 len;
	__u8 status;
	__u8 service_response;
	__u8 sense[SCSI_SENSE_BUFFERSIZE];
};

/*
 * The r02 specs define this version of the SENSE IU data structure.
 * It's still in use by several different firmware releases.
 */
struct sense_iu_r02 {
	__u8 iu_id;
	__u8 rsvd1;
	__be16 tag;
	__u8 status;
	__u8 rsvd2;
	__be16 len;
	__u8 sense[SCSI_SENSE_BUFFERSIZE];
};

struct uas_dev_info {
	struct usb_interface *intf;
	struct usb_device *udev;
	struct usb_anchor cmd_urbs;
	struct usb_anchor sense_urbs;
	struct usb_anchor data_urbs;
	int qdepth, num_streams;
	struct response_iu response;
	unsigned cmd_pipe, status_pipe, data_in_pipe, data_out_pipe;
	unsigned long flags;
#define UAS_FLIDX_USE_STREAMS	0
#define UAS_FLIDX_RESETTING		1
#define UAS_FLIDX_DISCONNECTING	2
	unsigned long quirks;
#define UAS_SENSE_IU_R01	(1 << 0)
#define UAS_SENSE_IU_R02	(1 << 1)
#define UAS_SENSE_IU_2R00	(1 << 2)
#define UAS_NO_ATA_PASS_THRU	(1 << 3)
#define UAS_NO_TEST_UNIT_READY	(1 << 4)
#define UAS_INCOMPATIBLE_DEVICE	(1 << 31)
	struct scsi_cmnd *cmnd;
	spinlock_t lock;
};

#define UAS_TMF_TAG				1
#define UAS_CMD_UNTAGGED_TAG	2
#define UAS_CMD_TAG_OFFS		3

#define UAS_PROBE	0
#define UAS_DISCONNECT	1
#define UAS_PREV_RESET	2
#define UAS_POST_RESET	3

enum {
	SUBMIT_STATUS_URB	= (1 << 1),
	ALLOC_DATA_IN_URB	= (1 << 2),
	SUBMIT_DATA_IN_URB	= (1 << 3),
	ALLOC_DATA_OUT_URB	= (1 << 4),
	SUBMIT_DATA_OUT_URB	= (1 << 5),
	ALLOC_CMD_URB		= (1 << 6),
	SUBMIT_CMD_URB		= (1 << 7),
	COMMAND_INFLIGHT        = (1 << 8),
	DATA_IN_URB_INFLIGHT    = (1 << 9),
	DATA_OUT_URB_INFLIGHT   = (1 << 10),
	COMMAND_COMPLETED       = (1 << 11),
	COMMAND_ABORTED         = (1 << 12),
	UNLINK_DATA_URBS		= (1 << 13),
	IS_IN_WORK_LIST 		= (1 << 14),
};

/* Overrides scsi_pointer */
struct uas_cmd_info {
	unsigned int state;
	unsigned int stream;
	struct urb *cmd_urb;
	struct urb *data_in_urb;
	struct urb *data_out_urb;
	struct list_head list;
};

/* I hate forward declarations, but I actually have a loop */
static int uas_submit_urbs(struct scsi_cmnd *cmnd,
				struct uas_dev_info *devinfo, gfp_t gfp);
static void uas_do_work(struct work_struct *work);
static int uas_try_complete(struct scsi_cmnd *cmnd, const char *caller);
static void uas_configure_endpoints(struct uas_dev_info *devinfo);

static DECLARE_WORK(uas_work, uas_do_work);
static DEFINE_SPINLOCK(uas_work_lock);
static LIST_HEAD(uas_work_list);

#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35))
extern int usb_alloc_streams(struct usb_interface *interface,
		struct usb_host_endpoint **eps, unsigned int num_eps,
		unsigned int num_streams, gfp_t mem_flags);
extern void usb_free_streams(struct usb_interface *interface,
		struct usb_host_endpoint **eps, unsigned int num_eps,
		gfp_t mem_flags);
#endif

extern void usb_run_bot_mode_notification(struct usb_device *hdev,
		unsigned int portnum);

static void uas_update_uas_device(struct usb_interface *intf, int type)
{
	struct usb_hcd *hcd;
	struct usb_device *udev = interface_to_usbdev(intf);

	hcd = bus_to_hcd(udev->bus);
	if (hcd->driver->update_uas_device)
		hcd->driver->update_uas_device(hcd, udev, type);
}

static void uas_unlink_data_urbs(struct uas_dev_info *devinfo,
				 struct uas_cmd_info *cmdinfo)
{
	unsigned long flags;

	/*
	 * The UNLINK_DATA_URBS flag makes sure uas_try_complete
	 * (called by urb completion) doesn't release cmdinfo
	 * underneath us.
	 */
	spin_lock_irqsave(&devinfo->lock, flags);
	cmdinfo->state |= UNLINK_DATA_URBS;
	spin_unlock_irqrestore(&devinfo->lock, flags);

	if (cmdinfo->data_in_urb)
		usb_unlink_urb(cmdinfo->data_in_urb);
	if (cmdinfo->data_out_urb)
		usb_unlink_urb(cmdinfo->data_out_urb);

	spin_lock_irqsave(&devinfo->lock, flags);
	cmdinfo->state &= ~UNLINK_DATA_URBS;
	spin_unlock_irqrestore(&devinfo->lock, flags);
}

static void uas_do_work(struct work_struct *work)
{
	struct uas_cmd_info *cmdinfo;
	struct uas_cmd_info *temp;
	struct list_head list;
	unsigned long flags;
	int err;

	spin_lock_irq(&uas_work_lock);
	list_replace_init(&uas_work_list, &list);
	spin_unlock_irq(&uas_work_lock);

	list_for_each_entry_safe(cmdinfo, temp, &list, list) {
		struct scsi_pointer *scp = (void *)cmdinfo;
		struct scsi_cmnd *cmnd = container_of(scp,
							struct scsi_cmnd, SCp);
		struct uas_dev_info *devinfo = (void *)cmnd->device->hostdata;
		spin_lock_irqsave(&devinfo->lock, flags);
		err = uas_submit_urbs(cmnd, cmnd->device->hostdata, GFP_ATOMIC);
		if (!err)
			cmdinfo->state &= ~IS_IN_WORK_LIST;
		spin_unlock_irqrestore(&devinfo->lock, flags);
		if (err) {
			list_del(&cmdinfo->list);
			spin_lock_irq(&uas_work_lock);
			list_add_tail(&cmdinfo->list, &uas_work_list);
			spin_unlock_irq(&uas_work_lock);
			schedule_work(&uas_work);
		}
	}
}

static void uas_abort_work(struct uas_dev_info *devinfo)
{
	struct uas_cmd_info *cmdinfo;
	struct uas_cmd_info *temp;
	struct list_head list;
	unsigned long flags;

	spin_lock_irq(&uas_work_lock);
	list_replace_init(&uas_work_list, &list);
	spin_unlock_irq(&uas_work_lock);

	spin_lock_irqsave(&devinfo->lock, flags);
	list_for_each_entry_safe(cmdinfo, temp, &list, list) {
		struct scsi_pointer *scp = (void *)cmdinfo;
		struct scsi_cmnd *cmnd = container_of(scp,
							struct scsi_cmnd, SCp);
		struct uas_dev_info *di = (void *)cmnd->device->hostdata;

		if (di == devinfo) {
			cmdinfo->state |= COMMAND_ABORTED;
			cmdinfo->state &= ~IS_IN_WORK_LIST;
			if (test_bit(UAS_FLIDX_RESETTING, &devinfo->flags) ||
				test_bit(UAS_FLIDX_DISCONNECTING, &devinfo->flags)) {
				/* uas_stat_cmplt() will not do that
				 * when a device reset is in
				 * progress */
				cmdinfo->state &= ~COMMAND_INFLIGHT;
			}
			uas_try_complete(cmnd, __func__);
		} else {
			/* not our uas device, relink into list */
			list_del(&cmdinfo->list);
			spin_lock_irq(&uas_work_lock);
			list_add_tail(&cmdinfo->list, &uas_work_list);
			spin_unlock_irq(&uas_work_lock);
		}
	}
	spin_unlock_irqrestore(&devinfo->lock, flags);
}

static void uas_sense(struct urb *urb, struct scsi_cmnd *cmnd)
{
	struct Scsi_Host *shost = urb->context;
	struct uas_dev_info *devinfo = (void *)shost->hostdata[0];
	struct scsi_device *sdev = cmnd->device;
	unsigned len;
	int newlen;
	char *data = urb->transfer_buffer;

	if (!(data[4] | data[6])) {
		cmnd->result = SAM_STAT_GOOD;
		return;
	}

	if (!(devinfo->quirks & 
		(UAS_SENSE_IU_R01 | UAS_SENSE_IU_R02 | UAS_SENSE_IU_2R00))) {
		if ((data[8] & 0x70) == 0x70) {
			if (data[5]) {
				devinfo->quirks |= UAS_SENSE_IU_R01;
			} else {
				devinfo->quirks |= UAS_SENSE_IU_R02;
			}
		} else {
			devinfo->quirks |= UAS_SENSE_IU_2R00;
		}

		dev_info(&devinfo->udev->dev,
			"%s: quirks = 0x%08lx\n", __func__, devinfo->quirks);
	}

	if (devinfo->quirks & UAS_SENSE_IU_R01) {
		struct sense_iu_r01 *sense_iu_r01 = urb->transfer_buffer;

		len = be16_to_cpup(&sense_iu_r01->len) - 2;
		if (len + 8 != urb->actual_length) {
			newlen = min(len + 8, urb->actual_length) - 8;
			if (newlen < 0)
				newlen = 0;
			sdev_printk(KERN_DEBUG, sdev, "%s (r01): urb length %d "
				"disagrees with IU sense data length %d, "
				"using %d bytes of sense data\n", __func__,
					urb->actual_length, len, newlen);
			len = newlen;
		}
		memcpy(cmnd->sense_buffer, sense_iu_r01->sense, len);
		cmnd->result = sense_iu_r01->status;
	} else if (devinfo->quirks & UAS_SENSE_IU_R02) {
		struct sense_iu_r02 *sense_iu_r02 = urb->transfer_buffer;

		len = be16_to_cpup(&sense_iu_r02->len);
		if (len + 8 != urb->actual_length) {
			newlen = min(len + 8, urb->actual_length) - 8;
			if (newlen < 0)
				newlen = 0;
			sdev_printk(KERN_DEBUG, sdev, "%s (r02): urb length %d "
				"disagrees with IU sense data length %d, "
				"using %d bytes of sense data\n", __func__,
					urb->actual_length, len, newlen);
			len = newlen;
		}
		memcpy(cmnd->sense_buffer, sense_iu_r02->sense, len);
		cmnd->result = sense_iu_r02->status;
	} else {
		struct sense_iu *sense_iu = urb->transfer_buffer;

		len = be16_to_cpup(&sense_iu->len);
		if (len + 16 != urb->actual_length) {
			newlen = min(len + 16, urb->actual_length) - 16;
			if (newlen < 0)
				newlen = 0;
			sdev_printk(KERN_DEBUG, sdev, "%s: urb length %d "
				"disagrees with IU sense data length %d, "
				"using %d bytes of sense data\n", __func__,
					urb->actual_length, len, newlen);
			len = newlen;
		}
		memcpy(cmnd->sense_buffer, sense_iu->sense, len);
		cmnd->result = sense_iu->status;
	}
}

static void uas_log_cmd_state(struct scsi_cmnd *cmnd, const char *caller)
{
	struct uas_cmd_info *ci = (void *)&cmnd->SCp;

	scmd_printk(KERN_INFO, cmnd, "%s cmd:%p (0x%02x) tag %d, inflight:"
		    "%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n",
		    caller, cmnd, cmnd->cmnd[0], cmnd->request->tag,
		    (ci->state & SUBMIT_STATUS_URB)     ? " s-st"  : "",
		    (ci->state & ALLOC_DATA_IN_URB)     ? " a-in"  : "",
		    (ci->state & SUBMIT_DATA_IN_URB)    ? " s-in"  : "",
		    (ci->state & ALLOC_DATA_OUT_URB)    ? " a-out" : "",
		    (ci->state & SUBMIT_DATA_OUT_URB)   ? " s-out" : "",
		    (ci->state & ALLOC_CMD_URB)         ? " a-cmd" : "",
		    (ci->state & SUBMIT_CMD_URB)        ? " s-cmd" : "",
		    (ci->state & COMMAND_INFLIGHT)      ? " CMD"   : "",
		    (ci->state & DATA_IN_URB_INFLIGHT)  ? " IN"    : "",
		    (ci->state & DATA_OUT_URB_INFLIGHT) ? " OUT"   : "",
		    (ci->state & COMMAND_COMPLETED)     ? " done"  : "",
		    (ci->state & COMMAND_ABORTED)		? " abort" : "",
		    (ci->state & UNLINK_DATA_URBS)		? " unlink": "",
		    (ci->state & IS_IN_WORK_LIST)		? " work"  : "");
}

static int uas_try_complete(struct scsi_cmnd *cmnd, const char *caller)
{
	struct uas_cmd_info *cmdinfo = (void *)&cmnd->SCp;

	if (cmdinfo->state & (COMMAND_INFLIGHT |
			      DATA_IN_URB_INFLIGHT |
		          DATA_OUT_URB_INFLIGHT |
		          UNLINK_DATA_URBS))
		return -EBUSY;
	BUG_ON(cmdinfo->state & COMMAND_COMPLETED);
	cmdinfo->state |= COMMAND_COMPLETED;
	usb_free_urb(cmdinfo->data_in_urb);
	usb_free_urb(cmdinfo->data_out_urb);
	if (cmdinfo->state & COMMAND_ABORTED) {
		scmd_printk(KERN_INFO, cmnd, "abort completed\n");
		cmnd->result = DID_ABORT << 16;
	}
	cmnd->scsi_done(cmnd);
	return 0;
}

static void uas_xfer_data(struct urb *urb, struct scsi_cmnd *cmnd,
			  unsigned direction)
{
	struct uas_cmd_info *cmdinfo = (void *)&cmnd->SCp;
	int err;

	cmdinfo->state |= direction | SUBMIT_STATUS_URB;
	err = uas_submit_urbs(cmnd, cmnd->device->hostdata, GFP_ATOMIC);
	if (err) {
		spin_lock(&uas_work_lock);
		list_add_tail(&cmdinfo->list, &uas_work_list);
		cmdinfo->state |= IS_IN_WORK_LIST;
		spin_unlock(&uas_work_lock);
		schedule_work(&uas_work);
	}
}

static void uas_stat_cmplt(struct urb *urb)
{
	struct iu *iu = urb->transfer_buffer;
	struct Scsi_Host *shost = urb->context;
	struct uas_dev_info *devinfo = (void *)shost->hostdata[0];
	struct scsi_cmnd *cmnd;
	struct uas_cmd_info *cmdinfo;
	unsigned long flags;
	u16 tag;

	if (urb->status) {
		dev_err(&urb->dev->dev, "URB BAD STATUS %d\n", urb->status);
		usb_free_urb(urb);
		return;
	}

	if (test_bit(UAS_FLIDX_RESETTING, &devinfo->flags) ||
		test_bit(UAS_FLIDX_DISCONNECTING, &devinfo->flags)) {
		usb_free_urb(urb);
		return;
	}

	spin_lock_irqsave(&devinfo->lock, flags);
	tag = be16_to_cpup(&iu->tag);
	if (tag == UAS_TMF_TAG)
		cmnd = NULL;
	else if (tag == UAS_CMD_UNTAGGED_TAG)
		cmnd = devinfo->cmnd;
	else
		cmnd = scsi_host_find_tag(shost, tag - UAS_CMD_TAG_OFFS);

	if (!cmnd) {
		if (iu->iu_id == IU_ID_RESPONSE) {
			/* store results for uas_eh_task_mgmt() */
			memcpy(&devinfo->response, iu, sizeof(devinfo->response));
		}
		usb_free_urb(urb);
		spin_unlock_irqrestore(&devinfo->lock, flags);
		return;
	}

	cmdinfo = (void *)&cmnd->SCp;
	switch (iu->iu_id) {
	case IU_ID_STATUS:
		if (devinfo->cmnd == cmnd)
			devinfo->cmnd = NULL;

		uas_sense(urb, cmnd);
		if (cmnd->result != 0) {
			/* cancel data transfers on error */
			spin_unlock_irqrestore(&devinfo->lock, flags);
			uas_unlink_data_urbs(devinfo, cmdinfo);
			spin_lock_irqsave(&devinfo->lock, flags);
		}
		cmdinfo->state &= ~COMMAND_INFLIGHT;
		uas_try_complete(cmnd, __func__);
		break;
	case IU_ID_READ_READY:
		uas_xfer_data(urb, cmnd, SUBMIT_DATA_IN_URB);
		break;
	case IU_ID_WRITE_READY:
		uas_xfer_data(urb, cmnd, SUBMIT_DATA_OUT_URB);
		break;
	default:
		scmd_printk(KERN_ERR, cmnd,
			"Bogus IU (%d) received on status pipe\n", iu->iu_id);
	}
	usb_free_urb(urb);
	spin_unlock_irqrestore(&devinfo->lock, flags);
}

static void uas_data_cmplt(struct urb *urb)
{
	struct scsi_cmnd *cmnd = urb->context;
	struct uas_cmd_info *cmdinfo = (void *)&cmnd->SCp;
	struct uas_dev_info *devinfo = (void *)cmnd->device->hostdata;
	struct scsi_data_buffer *sdb = NULL;
	unsigned long flags;

#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35))
	kfree(urb->sg);
#endif

	spin_lock_irqsave(&devinfo->lock, flags);
	if (cmdinfo->data_in_urb == urb) {
		sdb = scsi_in(cmnd);
		cmdinfo->state &= ~DATA_IN_URB_INFLIGHT;
	} else if (cmdinfo->data_out_urb == urb) {
		sdb = scsi_out(cmnd);
		cmdinfo->state &= ~DATA_OUT_URB_INFLIGHT;
	}
	BUG_ON(sdb == NULL);
	if (urb->status) {
		/* error: no data transfered */
		sdb->resid = sdb->length;
	} else {
		sdb->resid = sdb->length - urb->actual_length;
	}
	uas_try_complete(cmnd, __func__);
	spin_unlock_irqrestore(&devinfo->lock, flags);
}

static struct urb *uas_alloc_data_urb(struct uas_dev_info *devinfo, gfp_t gfp,
				      unsigned int pipe, u16 stream_id,
				      struct scsi_cmnd *cmnd,
				      enum dma_data_direction dir)
{
	struct usb_device *udev = devinfo->udev;
	struct urb *urb = usb_alloc_urb(0, gfp);
	struct scsi_data_buffer *sdb = (dir == DMA_FROM_DEVICE)
		? scsi_in(cmnd) : scsi_out(cmnd);

	if (!urb)
		goto out;

#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35))
	urb->sg = kzalloc(sizeof(struct usb_sg_request), gfp);
	if (urb->sg == NULL) {
		usb_free_urb(urb);
		urb = NULL;
		goto out;
	}
#endif

	usb_fill_bulk_urb(urb, udev, pipe, NULL, sdb->length,
			  uas_data_cmplt, cmnd);
	if (test_bit(UAS_FLIDX_USE_STREAMS, &devinfo->flags))
		urb->stream_id = stream_id;
#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35))
	urb->num_sgs = sdb->table.nents;
	urb->sg->sg = sdb->table.sgl;
#else
	urb->num_sgs = udev->bus->sg_tablesize ? sdb->table.nents : 0;
	urb->sg = sdb->table.sgl;
#endif
 out:
	return urb;
}

static struct urb *uas_alloc_sense_urb(struct uas_dev_info *devinfo, gfp_t gfp,
				       struct Scsi_Host *shost, u16 stream_id)
{
	struct usb_device *udev = devinfo->udev;
	struct urb *urb = usb_alloc_urb(0, gfp);
	struct sense_iu *iu;

	if (!urb)
		goto out;

	iu = kzalloc(sizeof(*iu), gfp);
	if (!iu)
		goto free;

	usb_fill_bulk_urb(urb, udev, devinfo->status_pipe, iu, sizeof(*iu),
						uas_stat_cmplt, shost);
	urb->stream_id = stream_id;
	urb->transfer_flags |= URB_FREE_BUFFER;
 out:
	return urb;
 free:
	usb_free_urb(urb);
	return NULL;
}

static struct urb *uas_alloc_cmd_urb(struct uas_dev_info *devinfo, gfp_t gfp,
					struct scsi_cmnd *cmnd, u16 stream_id)
{
	struct usb_device *udev = devinfo->udev;
	struct scsi_device *sdev = cmnd->device;
	struct urb *urb = usb_alloc_urb(0, gfp);
	struct command_iu *iu;
	int len;

	if (!urb)
		goto out;

	len = cmnd->cmd_len - 16;
	if (len < 0)
		len = 0;
	len = ALIGN(len, 4);
	iu = kzalloc(sizeof(*iu) + len, gfp);
	if (!iu)
		goto free;

	iu->iu_id = IU_ID_COMMAND;
	if (blk_rq_tagged(cmnd->request))
		iu->tag = cpu_to_be16(cmnd->request->tag + UAS_CMD_TAG_OFFS);
	else
		iu->tag = cpu_to_be16(UAS_CMD_UNTAGGED_TAG);
	iu->prio_attr = UAS_SIMPLE_TAG;
	iu->len = len;
	int_to_scsilun(sdev->lun, &iu->lun);
	memcpy(iu->cdb, cmnd->cmnd, cmnd->cmd_len);

	usb_fill_bulk_urb(urb, udev, devinfo->cmd_pipe, iu, sizeof(*iu) + len,
							usb_free_urb, NULL);
	urb->transfer_flags |= URB_FREE_BUFFER;
 out:
	return urb;
 free:
	usb_free_urb(urb);
	return NULL;
}

#if defined(CONFIG_USB_UAS_ENABLE_TASK_MANAGEMENT)
static int uas_submit_task_urb(struct scsi_cmnd *cmnd, gfp_t gfp,
			       u8 function, u16 stream_id)
{
	struct uas_dev_info *devinfo = (void *)cmnd->device->hostdata;
	struct usb_device *udev = devinfo->udev;
	struct urb *urb = usb_alloc_urb(0, gfp);
	struct task_mgmt_iu *iu;
	int err = -ENOMEM;

	if (!urb)
		goto err;

	iu = kzalloc(sizeof(*iu), gfp);
	if (!iu)
		goto err;

	iu->iu_id = IU_ID_TASK_MGMT;
	iu->tag = cpu_to_be16(stream_id);
	int_to_scsilun(cmnd->device->lun, &iu->lun);

	iu->function = function;
	switch (function) {
	case TMF_ABORT_TASK:
		if (blk_rq_tagged(cmnd->request))
			iu->task_tag = cpu_to_be16(cmnd->request->tag + UAS_CMD_TAG_OFFS);
		else
			iu->task_tag = cpu_to_be16(UAS_CMD_UNTAGGED_TAG);
		break;
	}

	usb_fill_bulk_urb(urb, udev, devinfo->cmd_pipe, iu, sizeof(*iu),
			  usb_free_urb, NULL);
	urb->transfer_flags |= URB_FREE_BUFFER;

	err = usb_submit_urb(urb, gfp);
	if (err)
		goto err;
	usb_anchor_urb(urb, &devinfo->cmd_urbs);

	return 0;

err:
	usb_free_urb(urb);
	return err;
}
#endif

/*
 * Why should I request the Status IU before sending the Command IU?  Spec
 * says to, but also says the device may receive them in any order.  Seems
 * daft to me.
 */

static int uas_submit_sense_urb(struct Scsi_Host *shost,
				gfp_t gfp, unsigned int stream)
{
	struct uas_dev_info *devinfo = (void *)shost->hostdata[0];
	struct urb *urb;

	urb = uas_alloc_sense_urb(devinfo, gfp, shost, stream);
	if (!urb)
		return SCSI_MLQUEUE_DEVICE_BUSY;
	if (usb_submit_urb(urb, gfp)) {
		shost_printk(KERN_INFO, shost,
			     "sense urb submission failure\n");
		usb_free_urb(urb);
		return SCSI_MLQUEUE_DEVICE_BUSY;
	}
	usb_anchor_urb(urb, &devinfo->sense_urbs);
	return 0;
}

static int uas_submit_urbs(struct scsi_cmnd *cmnd,
			   struct uas_dev_info *devinfo, gfp_t gfp)
{
	struct uas_cmd_info *cmdinfo = (void *)&cmnd->SCp;
	int err;

	if (cmdinfo->state & SUBMIT_STATUS_URB) {
		err = uas_submit_sense_urb(cmnd->device->host, gfp,
					   cmdinfo->stream);
		if (err) {
			return err;
		}
		cmdinfo->state &= ~SUBMIT_STATUS_URB;
	}

	if (cmdinfo->state & ALLOC_DATA_IN_URB) {
		cmdinfo->data_in_urb = uas_alloc_data_urb(devinfo, gfp,
					devinfo->data_in_pipe, cmdinfo->stream,
					cmnd, DMA_FROM_DEVICE);
		if (!cmdinfo->data_in_urb)
			return SCSI_MLQUEUE_DEVICE_BUSY;
		cmdinfo->state &= ~ALLOC_DATA_IN_URB;
	}

	if (cmdinfo->state & SUBMIT_DATA_IN_URB) {
		if (usb_submit_urb(cmdinfo->data_in_urb, gfp)) {
			scmd_printk(KERN_INFO, cmnd,
					"data in urb submission failure\n");
			return SCSI_MLQUEUE_DEVICE_BUSY;
		}
		cmdinfo->state &= ~SUBMIT_DATA_IN_URB;
		cmdinfo->state |= DATA_IN_URB_INFLIGHT;
		usb_anchor_urb(cmdinfo->data_in_urb, &devinfo->data_urbs);
	}

	if (cmdinfo->state & ALLOC_DATA_OUT_URB) {
		cmdinfo->data_out_urb = uas_alloc_data_urb(devinfo, gfp,
					devinfo->data_out_pipe, cmdinfo->stream,
					cmnd, DMA_TO_DEVICE);
		if (!cmdinfo->data_out_urb)
			return SCSI_MLQUEUE_DEVICE_BUSY;
		cmdinfo->state &= ~ALLOC_DATA_OUT_URB;
	}

	if (cmdinfo->state & SUBMIT_DATA_OUT_URB) {
		if (usb_submit_urb(cmdinfo->data_out_urb, gfp)) {
			scmd_printk(KERN_INFO, cmnd,
					"data out urb submission failure\n");
			return SCSI_MLQUEUE_DEVICE_BUSY;
		}
		cmdinfo->state &= ~SUBMIT_DATA_OUT_URB;
		cmdinfo->state |= DATA_OUT_URB_INFLIGHT;
		usb_anchor_urb(cmdinfo->data_out_urb, &devinfo->data_urbs);
	}

	if (cmdinfo->state & ALLOC_CMD_URB) {
		cmdinfo->cmd_urb = uas_alloc_cmd_urb(devinfo, gfp, cmnd,
						     cmdinfo->stream);
		if (!cmdinfo->cmd_urb)
			return SCSI_MLQUEUE_DEVICE_BUSY;
		cmdinfo->state &= ~ALLOC_CMD_URB;
	}

	if (cmdinfo->state & SUBMIT_CMD_URB) {
		usb_get_urb(cmdinfo->cmd_urb);
		if (usb_submit_urb(cmdinfo->cmd_urb, gfp)) {
			usb_put_urb(cmdinfo->cmd_urb);
			scmd_printk(KERN_INFO, cmnd,
					"cmd urb submission failure\n");
			return SCSI_MLQUEUE_DEVICE_BUSY;
		}
		usb_anchor_urb(cmdinfo->cmd_urb, &devinfo->cmd_urbs);
		usb_put_urb(cmdinfo->cmd_urb);
		cmdinfo->cmd_urb = NULL;
		cmdinfo->state &= ~SUBMIT_CMD_URB;
		cmdinfo->state |= COMMAND_INFLIGHT;
	}

	return 0;
}

/* To Report "Illegal Request: Invalid Field in CDB" */
static unsigned char uas_sense_invalidCDB[18] = {
	[0] = 0x70,				/* current error */
	[2] = ILLEGAL_REQUEST,	/* Illegal Request = 0x05 */
	[7] = 0x0a,				/* additional length */
	[12] = 0x24				/* Invalid Field in CDB */
};

static int uas_prev_queue_command(struct scsi_cmnd *cmnd)
{
	struct scsi_device *sdev = cmnd->device;
	struct uas_dev_info *devinfo = sdev->hostdata;
	int ret = -EINVAL;

	switch (cmnd->cmnd[0]) {
	case ATA_12:
	case ATA_16:
		if (devinfo->quirks & UAS_NO_ATA_PASS_THRU) {
			scmd_printk(KERN_DEBUG, cmnd, "reject cmd:%p (0x%02x)\n",
				cmnd, cmnd->cmnd[0]);
			cmnd->result = SAM_STAT_CHECK_CONDITION;
			memcpy(cmnd->sense_buffer, uas_sense_invalidCDB, sizeof(uas_sense_invalidCDB));
			ret = 0;
		}
		break;
	case TEST_UNIT_READY:
		if (devinfo->quirks & UAS_NO_TEST_UNIT_READY) {
			scmd_printk(KERN_DEBUG, cmnd, "ignore cmd:%p (0x%02x)\n",
				cmnd, cmnd->cmnd[0]);
			cmnd->result = SAM_STAT_GOOD;
			ret = 0;
		}
		break;
	default:
		break;
	}

	return ret;
}

#if (LINUX_VERSION_CODE > KERNEL_VERSION(2,6,36))
static int uas_queuecommand_lck(struct scsi_cmnd *cmnd,
					void (*done)(struct scsi_cmnd *))
#else
static int uas_queuecommand(struct scsi_cmnd *cmnd,
					void (*done)(struct scsi_cmnd *))
#endif
{
	struct scsi_device *sdev = cmnd->device;
	struct uas_dev_info *devinfo = sdev->hostdata;
	struct uas_cmd_info *cmdinfo = (void *)&cmnd->SCp;
	unsigned long flags;
	int err;

	BUILD_BUG_ON(sizeof(struct uas_cmd_info) > sizeof(struct scsi_pointer));

	if (test_bit(UAS_FLIDX_DISCONNECTING, &devinfo->flags)) {
		scmd_printk(KERN_DEBUG, cmnd, "fail cmd:%p (0x%02x) during disconnect\n",
			cmnd, cmnd->cmnd[0]);
		cmnd->result = DID_NO_CONNECT << 16;
		goto err_done;
	}

	if (test_bit(UAS_FLIDX_RESETTING, &devinfo->flags)) {
		scmd_printk(KERN_DEBUG, cmnd, "fail cmd:%p (0x%02x) during reset\n",
			cmnd, cmnd->cmnd[0]);
		cmnd->result = DID_ERROR << 16;
		goto err_done;
	}

	if (!uas_prev_queue_command(cmnd)) {
		goto err_done;
	}

	spin_lock_irqsave(&devinfo->lock, flags);
	if (devinfo->cmnd) {
		spin_unlock_irqrestore(&devinfo->lock, flags);
		return SCSI_MLQUEUE_DEVICE_BUSY;
	}

	if (blk_rq_tagged(cmnd->request)) {
		cmdinfo->stream = cmnd->request->tag + UAS_CMD_TAG_OFFS;
	} else {
		devinfo->cmnd = cmnd;
		cmdinfo->stream = UAS_CMD_UNTAGGED_TAG;
	}

	cmnd->scsi_done = done;

	INIT_LIST_HEAD(&cmdinfo->list);
	cmdinfo->state = SUBMIT_STATUS_URB |
			ALLOC_CMD_URB | SUBMIT_CMD_URB;

	switch (cmnd->sc_data_direction) {
	case DMA_FROM_DEVICE:
		cmdinfo->state |= ALLOC_DATA_IN_URB | SUBMIT_DATA_IN_URB;
		break;
	case DMA_BIDIRECTIONAL:
		cmdinfo->state |= ALLOC_DATA_IN_URB | SUBMIT_DATA_IN_URB;
	case DMA_TO_DEVICE:
		cmdinfo->state |= ALLOC_DATA_OUT_URB | SUBMIT_DATA_OUT_URB;
	case DMA_NONE:
		break;
	}

	if (!test_bit(UAS_FLIDX_USE_STREAMS, &devinfo->flags)) {
		cmdinfo->state &= ~(SUBMIT_DATA_IN_URB | SUBMIT_DATA_OUT_URB);
		cmdinfo->stream = 0;
	}

	err = uas_submit_urbs(cmnd, devinfo, GFP_ATOMIC);
	if (err) {
		/* If we did nothing, give up now */
		if (cmdinfo->state & SUBMIT_STATUS_URB) {
			spin_unlock_irqrestore(&devinfo->lock, flags);
			return SCSI_MLQUEUE_DEVICE_BUSY;
		}
		spin_lock(&uas_work_lock);
		list_add_tail(&cmdinfo->list, &uas_work_list);
		cmdinfo->state |= IS_IN_WORK_LIST;
		spin_unlock(&uas_work_lock);
		schedule_work(&uas_work);
	}

	spin_unlock_irqrestore(&devinfo->lock, flags);
	return 0;

err_done:
	done(cmnd);
	return 0;
}

#if (LINUX_VERSION_CODE > KERNEL_VERSION(2,6,36))
static DEF_SCSI_QCMD(uas_queuecommand)
#endif

static int uas_eh_task_mgmt(struct scsi_cmnd *cmnd,
			    const char *fname, u8 function)
{
#if defined(CONFIG_USB_UAS_ENABLE_TASK_MANAGEMENT)
	struct Scsi_Host *shost = cmnd->device->host;
	struct uas_dev_info *devinfo = (void *)shost->hostdata[0];
	u16 tag = UAS_TMF_TAG;
	unsigned long flags;

	spin_lock_irqsave(&devinfo->lock, flags);
	memset(&devinfo->response, 0, sizeof(devinfo->response));
	if (uas_submit_sense_urb(shost, GFP_ATOMIC, tag)) {
		shost_printk(KERN_INFO, shost,
			     "%s: %s: submit sense urb failed\n",
			     __func__, fname);
		spin_unlock_irqrestore(&devinfo->lock, flags);
		return FAILED;
	}
	if (uas_submit_task_urb(cmnd, GFP_ATOMIC, function, tag)) {
		shost_printk(KERN_INFO, shost,
			     "%s: %s: submit task mgmt urb failed\n",
			     __func__, fname);
		spin_unlock_irqrestore(&devinfo->lock, flags);
		return FAILED;
	}
	spin_unlock_irqrestore(&devinfo->lock, flags);

	if (usb_wait_anchor_empty_timeout(&devinfo->sense_urbs, 3000) == 0) {
		shost_printk(KERN_INFO, shost,
			     "%s: %s timed out\n", __func__, fname);
		return FAILED;
	}
	if (be16_to_cpu(devinfo->response.tag) != tag) {
		shost_printk(KERN_INFO, shost,
			     "%s: %s failed (wrong tag %d/%d)\n", __func__,
			     fname, be16_to_cpu(devinfo->response.tag), tag);
		return FAILED;
	}
	if (devinfo->response.response_code != RC_TMF_COMPLETE) {
		shost_printk(KERN_INFO, shost,
			     "%s: %s failed (rc 0x%x)\n", __func__,
			     fname, devinfo->response.response_code);
		return FAILED;
	}
	return SUCCESS;
#else
	return FAILED;
#endif
}

static int uas_eh_abort_handler(struct scsi_cmnd *cmnd)
{
	struct uas_cmd_info *cmdinfo = (void *)&cmnd->SCp;
	struct uas_dev_info *devinfo = (void *)cmnd->device->hostdata;
	unsigned long flags;
	int ret;

	uas_log_cmd_state(cmnd, __func__);
	spin_lock_irqsave(&devinfo->lock, flags);
	cmdinfo->state |= COMMAND_ABORTED;
	if (cmdinfo->state & IS_IN_WORK_LIST) {
		spin_lock(&uas_work_lock);
		list_del(&cmdinfo->list);
		cmdinfo->state &= ~IS_IN_WORK_LIST;
		spin_unlock(&uas_work_lock);
	}
	if (cmdinfo->state & COMMAND_INFLIGHT) {
		spin_unlock_irqrestore(&devinfo->lock, flags);
		ret = uas_eh_task_mgmt(cmnd, "ABORT TASK", TMF_ABORT_TASK);
	} else {
		spin_unlock_irqrestore(&devinfo->lock, flags);
		uas_unlink_data_urbs(devinfo, cmdinfo);
		spin_lock_irqsave(&devinfo->lock, flags);
		uas_try_complete(cmnd, __func__);
		spin_unlock_irqrestore(&devinfo->lock, flags);
		ret = SUCCESS;
	}
	return ret;
}

static int uas_eh_device_reset_handler(struct scsi_cmnd *cmnd)
{
	sdev_printk(KERN_INFO, cmnd->device, "%s\n", __func__);
	return uas_eh_task_mgmt(cmnd, "LOGICAL UNIT RESET",
				TMF_LOGICAL_UNIT_RESET);
}

static int uas_eh_bus_reset_handler(struct scsi_cmnd *cmnd)
{
	struct scsi_device *sdev = cmnd->device;
	struct uas_dev_info *devinfo = sdev->hostdata;
	struct usb_device *udev = devinfo->udev;
	int err;

	set_bit(UAS_FLIDX_RESETTING, &devinfo->flags);
	uas_abort_work(devinfo);
	usb_kill_anchored_urbs(&devinfo->cmd_urbs);
	usb_kill_anchored_urbs(&devinfo->sense_urbs);
	usb_kill_anchored_urbs(&devinfo->data_urbs);
	err = usb_lock_device_for_reset(udev, devinfo->intf);
	if (!err) {
		err = usb_reset_device(udev);
		usb_unlock_device(udev);

		if (!err) {
			uas_configure_endpoints(devinfo);
			clear_bit(UAS_FLIDX_RESETTING, &devinfo->flags);
			shost_printk(KERN_INFO, sdev->host, "%s success\n", __func__);
			return SUCCESS;
		}
	}

	clear_bit(UAS_FLIDX_RESETTING, &devinfo->flags);
	shost_printk(KERN_INFO, sdev->host, "%s FAILED\n", __func__);
	return FAILED;
}

static int uas_slave_alloc(struct scsi_device *sdev)
{
	sdev->hostdata = (void *)sdev->host->hostdata[0];
	return 0;
}

static int uas_slave_configure(struct scsi_device *sdev)
{
	struct uas_dev_info *devinfo = sdev->hostdata;
	blk_queue_rq_timeout(sdev->request_queue, 5 * HZ);
	scsi_set_tag_type(sdev, MSG_ORDERED_TAG);
	scsi_activate_tcq(sdev, devinfo->qdepth);
	return 0;
}

static struct scsi_host_template uas_host_template = {
	.module = THIS_MODULE,
	.name = "uas",
	.queuecommand = uas_queuecommand,
	.slave_alloc = uas_slave_alloc,
	.slave_configure = uas_slave_configure,
	.eh_abort_handler = uas_eh_abort_handler,
	.eh_device_reset_handler = uas_eh_device_reset_handler,
	.eh_bus_reset_handler = uas_eh_bus_reset_handler,
	.can_queue = 65536,	/* Is there a limit on the _host_ ? */
	.this_id = -1,
	.sg_tablesize = SG_NONE,
	.cmd_per_lun = 1,	/* until we override it */
	.skip_settle_delay = 1,
	.ordered_tag = 1,
};

static struct usb_device_id uas_usb_ids[] = {
	{ USB_DEVICE_VER(0x4971, 0x1012, 0x4798, 0x4798), .driver_info = UAS_INCOMPATIBLE_DEVICE },
	{ USB_DEVICE_VER(0x05e3, 0x0733, 0x5405, 0x5405), .driver_info = UAS_INCOMPATIBLE_DEVICE },
	{ USB_DEVICE_VER(0x059b, 0x0070, 0x0006, 0x0006), .driver_info = UAS_INCOMPATIBLE_DEVICE },
	{ USB_DEVICE_VER(0x1759, 0x5002, 0x2270, 0x2270), .driver_info = UAS_NO_TEST_UNIT_READY },
	{ USB_DEVICE_VER(0x2109, 0x0711, 0x0200, 0x0200), .driver_info = UAS_NO_ATA_PASS_THRU },
	{ USB_INTERFACE_INFO(USB_CLASS_MASS_STORAGE, USB_SC_SCSI, USB_PR_BULK) },
	{ USB_INTERFACE_INFO(USB_CLASS_MASS_STORAGE, USB_SC_SCSI, USB_PR_UAS) },
	/* 0xaa is a prototype device I happen to have access to */
	{ USB_INTERFACE_INFO(USB_CLASS_MASS_STORAGE, USB_SC_SCSI, 0xaa) },
	{ }
};
MODULE_DEVICE_TABLE(usb, uas_usb_ids);

static int uas_is_interface(struct usb_host_interface *intf)
{
	return (intf->desc.bInterfaceClass == USB_CLASS_MASS_STORAGE &&
		intf->desc.bInterfaceSubClass == USB_SC_SCSI &&
		intf->desc.bInterfaceProtocol == USB_PR_UAS);
}

static int uas_isnt_supported(struct usb_device *udev)
{
	struct usb_hcd *hcd = bus_to_hcd(udev->bus);

	dev_warn(&udev->dev, "The driver for the USB controller %s does not "
			"support scatter-gather which is\n",
			hcd->driver->description);
	dev_warn(&udev->dev, "required by the UAS driver. Please try an"
			"alternative USB controller if you wish to use UAS.\n");
	return -ENODEV;
}

static int uas_switch_interface(struct usb_device *udev,
						struct usb_interface *intf)
{
	int i;
	int sg_supported = udev->bus->sg_tablesize != 0;

	for (i = 0; i < intf->num_altsetting; i++) {
		struct usb_host_interface *alt = &intf->altsetting[i];

		if (uas_is_interface(alt)) {
			if (!sg_supported)
				return uas_isnt_supported(udev);
			return usb_set_interface(udev,
						alt->desc.bInterfaceNumber,
						alt->desc.bAlternateSetting);
		}
	}

	return -ENODEV;
}

static void uas_set_queue_depth(struct uas_dev_info *devinfo)
{
	int qdepth;

	/* Define the following cmd tag assignment:
	 * [1:TMF, 2:untagged, [3, num_streams]:tagged].
	 * Thus there are num_streams-3+1 = num_streams-2 tags
	 * for tagged commands. Report this number to the SCSI Core
	 * as the number of maximum commands we can queue, thus
	 * giving us a tag range [0, num_streams-3], which we
	 * offset by 3 (CMD_TAG_OFFS).
	 */
	qdepth = devinfo->num_streams - 2;
	if (qdepth <= 0) {
		/* Pathological case--perhaps fail discovery?
		 */
		dev_notice(&devinfo->udev->dev,
				"device supports too few streams (%d)\n",
				devinfo->num_streams);
		qdepth = max(1, devinfo->num_streams - 1);
	}

	devinfo->qdepth = qdepth;
}

static void uas_configure_endpoints(struct uas_dev_info *devinfo)
{
	struct usb_host_endpoint *eps[4] = { };
	struct usb_interface *intf = devinfo->intf;
	struct usb_device *udev = devinfo->udev;
	struct usb_host_endpoint *endpoint = intf->cur_altsetting->endpoint;
	unsigned i, n_endpoints = intf->cur_altsetting->desc.bNumEndpoints;
	unsigned char *extra;
	int len;

	devinfo->cmnd = NULL;

	for (i = 0; i < n_endpoints; i++) {
#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35))
		struct usb_host_ss_ep_comp *comp = endpoint[i].ss_ep_comp;

		if (!comp)
			continue;

		extra = comp->extra;
		len = comp->extralen;
#else		
		extra = endpoint[i].extra;
		len = endpoint[i].extralen;
#endif
		while (len > 1) {
			if (extra[1] == USB_DT_PIPE_USAGE) {
				unsigned pipe_id = extra[2];
				if (pipe_id > 0 && pipe_id < 5)
					eps[pipe_id - 1] = &endpoint[i];
				break;
			}
			len -= extra[0];
			extra += extra[0];
		}
	}

	/*
	 * Assume that if we didn't find a control pipe descriptor, we're
	 * using a device with old firmware that happens to be set up like
	 * this.
	 */
	if (!eps[0]) {
		devinfo->cmd_pipe = usb_sndbulkpipe(udev, 1);
		devinfo->status_pipe = usb_rcvbulkpipe(udev, 1);
		devinfo->data_in_pipe = usb_rcvbulkpipe(udev, 2);
		devinfo->data_out_pipe = usb_sndbulkpipe(udev, 2);

		eps[1] = usb_pipe_endpoint(udev, devinfo->status_pipe);
		eps[2] = usb_pipe_endpoint(udev, devinfo->data_in_pipe);
		eps[3] = usb_pipe_endpoint(udev, devinfo->data_out_pipe);
	} else {
		devinfo->cmd_pipe = usb_sndbulkpipe(udev,
						eps[0]->desc.bEndpointAddress);
		devinfo->status_pipe = usb_rcvbulkpipe(udev,
						eps[1]->desc.bEndpointAddress);
		devinfo->data_in_pipe = usb_rcvbulkpipe(udev,
						eps[2]->desc.bEndpointAddress);
		devinfo->data_out_pipe = usb_sndbulkpipe(udev,
						eps[3]->desc.bEndpointAddress);
	}

	devinfo->num_streams = usb_alloc_streams(devinfo->intf, eps + 1, 3, 256,
								GFP_KERNEL);
	if (devinfo->num_streams < 0) {
		devinfo->qdepth = 256;
		clear_bit(UAS_FLIDX_USE_STREAMS, &devinfo->flags);
	} else {
		uas_set_queue_depth(devinfo);
		set_bit(UAS_FLIDX_USE_STREAMS, &devinfo->flags);
		dev_info(&udev->dev, "%s: allocated streams %d\n", __func__, devinfo->num_streams);
	}
}

static void uas_free_streams(struct uas_dev_info *devinfo)
{
	struct usb_device *udev = devinfo->udev;
	struct usb_host_endpoint *eps[3];

	eps[0] = usb_pipe_endpoint(udev, devinfo->status_pipe);
	eps[1] = usb_pipe_endpoint(udev, devinfo->data_in_pipe);
	eps[2] = usb_pipe_endpoint(udev, devinfo->data_out_pipe);
	usb_free_streams(devinfo->intf, eps, 3, GFP_KERNEL);
}

static int uas_is_hcd_support_stream(struct usb_device *udev)
{
	struct usb_hcd *hcd = bus_to_hcd(udev->bus);
	int ret = -ENODEV;

	switch (hcd->chip_id) {
	case HCD_CHIP_ID_ETRON_EJ168:
	case HCD_CHIP_ID_ETRON_EJ188:
		ret = 0;
		break;
	default:
		break;
	}

	return ret;
}

static void uas_adjust_quirks(struct uas_dev_info *devinfo, const struct usb_device_id *id)
{
	unsigned long mask = (UAS_SENSE_IU_R01 | UAS_SENSE_IU_R02 | UAS_SENSE_IU_2R00 |
			UAS_NO_ATA_PASS_THRU | UAS_NO_TEST_UNIT_READY);

	devinfo->quirks = id->driver_info & mask;
	if (devinfo->quirks)		
		dev_info(&devinfo->udev->dev, "%s: quirks = 0x%08lx\n", __func__, devinfo->quirks);
}

static int uas_is_incompatible_device(struct usb_device *udev, const struct usb_device_id *id)
{
#define USB_QUIRK_BOT_MODE		0x40000000

	if (udev->speed != USB_SPEED_SUPER)
		return 0;
	else if (udev->quirks & USB_QUIRK_BOT_MODE)
		return 0;
	else if (id->driver_info & UAS_INCOMPATIBLE_DEVICE) {
		usb_set_device_state(udev, USB_STATE_NOTATTACHED);
		usb_run_bot_mode_notification(udev->parent, udev->portnum);
		return 0;
	}

	return -ENODEV;
}

/*
 * XXX: What I'd like to do here is register a SCSI host for each USB host in
 * the system.  Follow usb-storage's design of registering a SCSI host for
 * each USB device for the moment.  Can implement this by walking up the
 * USB hierarchy until we find a USB host.
 */
static int uas_probe(struct usb_interface *intf, const struct usb_device_id *id)
{
	int result;
	struct Scsi_Host *shost;
	struct uas_dev_info *devinfo;
	struct usb_device *udev = interface_to_usbdev(intf);

	if (uas_is_hcd_support_stream(udev))
		return -ENODEV;

	if (!uas_is_incompatible_device(udev, id))
		return -ENODEV;

	if (uas_switch_interface(udev, intf))
		return -ENODEV;

	dev_info(&udev->dev, "UAS device detected\n");
	devinfo = kzalloc(sizeof(struct uas_dev_info), GFP_KERNEL);
	if (!devinfo)
		return -ENOMEM;

	result = -ENOMEM;
	shost = scsi_host_alloc(&uas_host_template, sizeof(void *));
	if (!shost)
		goto free;

	shost->max_cmd_len = 16 + 252;
	shost->max_id = 1;
	shost->sg_tablesize = udev->bus->sg_tablesize;

	devinfo->intf = intf;
	devinfo->udev = udev;
	init_usb_anchor(&devinfo->cmd_urbs);
	init_usb_anchor(&devinfo->sense_urbs);
	init_usb_anchor(&devinfo->data_urbs);
	spin_lock_init(&devinfo->lock);
	uas_adjust_quirks(devinfo, id);
	uas_update_uas_device(intf, UAS_PROBE);
	uas_configure_endpoints(devinfo);

	shost->can_queue = devinfo->qdepth;
	shost->cmd_per_lun = devinfo->qdepth;

	result = scsi_init_shared_tag_map(shost, devinfo->qdepth);
	if (result)
		goto deconfig_eps;

	result = scsi_add_host(shost, &intf->dev);
	if (result)
		goto deconfig_eps;

	shost->hostdata[0] = (unsigned long)devinfo;

	scsi_scan_host(shost);
	usb_set_intfdata(intf, shost);
	return result;

deconfig_eps:
	uas_free_streams(devinfo);
	uas_update_uas_device(intf, UAS_DISCONNECT);
 free:
	kfree(devinfo);
	if (shost)
		scsi_host_put(shost);
	return result;
}

static int uas_pre_reset(struct usb_interface *intf)
{
/* XXX: Need to return 1 if it's not our device in error handling */
	uas_update_uas_device(intf, UAS_PREV_RESET);
	return 0;
}

static int uas_post_reset(struct usb_interface *intf)
{
/* XXX: Need to return 1 if it's not our device in error handling */
	uas_update_uas_device(intf, UAS_POST_RESET);
	return 0;
}

static void uas_disconnect(struct usb_interface *intf)
{
	struct Scsi_Host *shost = usb_get_intfdata(intf);
	struct uas_dev_info *devinfo = (void *)shost->hostdata[0];

	set_bit(UAS_FLIDX_DISCONNECTING, &devinfo->flags);
	uas_abort_work(devinfo);
	usb_kill_anchored_urbs(&devinfo->cmd_urbs);
	usb_kill_anchored_urbs(&devinfo->sense_urbs);
	usb_kill_anchored_urbs(&devinfo->data_urbs);
	scsi_remove_host(shost);
	uas_free_streams(devinfo);
	uas_update_uas_device(intf, UAS_DISCONNECT);
	kfree(devinfo);
}

/*
 * XXX: Should this plug into libusual so we can auto-upgrade devices from
 * Bulk-Only to UAS?
 */
static struct usb_driver uas_driver = {
	.name = "uas",
	.probe = uas_probe,
	.disconnect = uas_disconnect,
	.pre_reset = uas_pre_reset,
	.post_reset = uas_post_reset,
	.id_table = uas_usb_ids,
};

#if (LINUX_VERSION_CODE > KERNEL_VERSION(3,3,0))
module_usb_driver(uas_driver);
#else
static int uas_init(void)
{
	return usb_register(&uas_driver);
}

static void uas_exit(void)
{
	usb_deregister(&uas_driver);
}

module_init(uas_init);
module_exit(uas_exit);
#endif

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Matthew Wilcox and Sarah Sharp");
