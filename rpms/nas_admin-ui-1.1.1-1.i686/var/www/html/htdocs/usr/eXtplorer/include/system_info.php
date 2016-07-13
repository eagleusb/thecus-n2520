<?php
// ensure this file is being included by a parent file
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version $Id: system_info.php 116 2009-01-15 20:39:58Z soeren $
 * @package eXtplorer
 * @copyright soeren 2007
 * @author The eXtplorer project (http://sourceforge.net/projects/extplorer)
 * 
 * @license
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * Alternatively, the contents of this file may be used under the terms
 * of the GNU General Public License Version 2 or later (the "GPL"), in
 * which case the provisions of the GPL are applicable instead of
 * those above. If you wish to allow use of your version of this file only
 * under the terms of the GPL and not to allow others to use
 * your version of this file under the MPL, indicate your decision by
 * deleting  the provisions above and replace  them with the notice and
 * other provisions required by the GPL.  If you do not delete
 * the provisions above, a recipient may use your version of this file
 * under either the MPL or the GPL."
 * 
 */

function get_php_setting($val, $recommended=1) {
	$value = ini_get($val);
	$r = ( $value == $recommended ? 1 : 0);
	if( empty($value)) {
		$onoff = 1;
	}
	else {
		$onoff = 0;
	}
	return $r ? '<span style="color: green;">' . $GLOBALS['messages']['sionoff'][$onoff] . '</span>' : '<span style="color: red;">' . $GLOBALS['messages']['sionoff'][$onoff] . '</span>';
}

function get_server_software() {
	if (isset($_SERVER['SERVER_SOFTWARE'])) {
		return $_SERVER['SERVER_SOFTWARE'];
	} else if (($sf = getenv('SERVER_SOFTWARE'))) {
		return $sf;
	} else {
		return 'n/a';
	}
}

function system_info() {
	$version = $GLOBALS['ext_version'];
	//$tab = extGetParam( $_REQUEST, 'tab', 'tab1' );
	$width = 400;	// width of 100%
	
	?>
	<br />
	<div id="sysinfo">
	<div id="system-page" class="x-tab" title="<?php echo ext_Lang::msg( 'sisysteminfo' ) ?>">
	
	<table class="adminform">
	<tr>
		<td valign="top" width="250" style="font-weight:bold;">
		Logged in as:
		</td>
		<td><?php echo $_SESSION['s_user'] ?></td>
	<tr>
		<td valign="top" width="250" style="font-weight:bold;">
			<?php echo ext_lang::msg( 'sibuilton' ); ?>:
		</td>
		<td>
		<?php echo php_uname(); ?>
		</td>
	</tr>
	<tr>
		<td valign="top" style="font-weight:bold;">
			<?php echo ext_lang::msg( 'siphpversion' ); ?>:
		</td>
		<td>
		<?php echo phpversion(); ?>
		&nbsp;
		<?php echo phpversion() >= '4.3' ? '' : $GLOBALS['messages']['siphpupdate']; ?>
		</td>
	</tr>
	<tr>
		<td style="font-weight:bold;">
			<?php echo ext_lang::msg( 'siwebserver' ); ?>:
		</td>
		<td>
		<?php echo get_server_software(); ?>
		</td>
	</tr>
	<tr>
		<td style="font-weight:bold;">
			<?php echo ext_lang::msg( 'siwebsphpif' ); ?>:
		</td>
		<td>
		<?php echo php_sapi_name(); ?>
		</td>
	</tr>
	<tr>
		<td style="font-weight:bold;">
			<?php echo ext_lang::msg( 'simamboversion' ); ?>:
		</td>
		<td>
		<?php echo $version; ?>
		</td>
	</tr>
	<tr>
		<td style="font-weight:bold;">
			<?php echo ext_lang::msg( 'siuseragent' ); ?>:
		</td>
		<td>
		<?php echo phpversion() <= "4.2.1" ? getenv( "HTTP_USER_AGENT" ) : $_SERVER['HTTP_USER_AGENT'];?>
		</td>
	</tr>
	<tr>
		<td valign="top" style="font-weight:bold;">
			<?php echo ext_lang::msg( 'sirelevantsettings' ); ?>:
		</td>
		<td>
			<table cellspacing="1" cellpadding="1" border="0">
			<tr>
				<td valign="top">
					<?php echo ext_lang::msg( 'sisafemode' ); ?>:
				</td>
				<td>
				<?php echo get_php_setting('safe_mode', 0); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sibasedir' ); ?>:
				</td>
				<td>
				<?php echo (($ob = ini_get('open_basedir')) ? $ob : 'none'); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sidisplayerrors' ); ?>:
				</td>
				<td>
				<?php echo get_php_setting('display_errors'); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sishortopentags' ); ?>:
				</td>
				<td>
				<?php echo get_php_setting('short_open_tag'); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sifileuploads' ); ?>:
				</td>
				<td>
				<?php echo get_php_setting('file_uploads'); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'simagicquotes' ); ?>:
				</td>
				<td>
				<?php echo get_php_setting('magic_quotes_gpc'); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'siregglobals' ); ?>:
				</td>
				<td>
				<?php echo get_php_setting('register_globals', 0); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sioutputbuf' ); ?>:
				</td>
				<td>
				<?php echo get_php_setting('output_buffering', 0); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sisesssavepath' ); ?>:
				</td>
				<td>
				<?php echo (( $sp=ini_get( 'session.save_path' )) ? $sp : 'none' ); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sisessautostart' ); ?>:
				</td>
				<td>
				<?php echo intval( ini_get( 'session.auto_start' ) ); ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sixmlenabled' ); ?>:
				</td>
				<td>
					<?php echo extension_loaded('xml') ? '<font style="color: green;">' . $GLOBALS['messages']['miscyesno'][0] . '</font>' : '<font style="color: red;">' . $GLOBALS['messages']['miscyesno'][1] . '</font>'; ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sizlibenabled' ); ?>:
				</td>
				<td>
				<?php echo extension_loaded('zlib') ? '<font style="color: green;">' . $GLOBALS['messages']['miscyesno'][0] . '</font>' : '<font style="color: red;">' . $GLOBALS['messages']['miscyesno'][1] . '</font>'; ?>
				</td>
			</tr>
			<tr>
				<td>
					<?php echo ext_lang::msg( 'sidisabledfuncs' ); ?>:
				</td>
				<td>
				<?php echo (( $df=ini_get('disable_functions' )) ? $df : 'none' ); ?>
				</td>
			</tr>
			</table>
		</td>
	</tr>
	</table>
	</div>
	<div id="php-page" class="x-tab" title="<?php echo ext_Lang::msg('siphpinfo' ); ?>">
	<table class="adminform">
	<tr>
		<th colspan="2">
			<?php echo ext_lang::msg( 'siphpinformation' ); ?>:
		</th>
	</tr>
	<tr>
		<td>
		<?php
		ob_start();
		phpinfo(INFO_GENERAL | INFO_CONFIGURATION | INFO_MODULES);
		$phpinfo = ob_get_contents();
		ob_end_clean();
		preg_match_all('#<body[^>]*>(.*)</body>#siU', $phpinfo, $output);
		$output = preg_replace('#<table#', '<table class="adminlist" align="center"', $output[1][0]);
		$output = preg_replace('#(\w),(\w)#', '\1, \2', $output);
		$output = preg_replace('#border="0" cellpadding="3" width="600"#', 'border="0" cellspacing="1" cellpadding="4" width="95%"', $output);
		$output = preg_replace('#<hr />#', '', $output);
		echo $output;
		?>
		</td>
	</tr>
	</table>
	</div>
	</div>
	<script type="text/javascript">
<!--
var tabs = new Ext.TabPanel( "sysinfo" );
tabs.addTab( "system-page","<?php echo ext_Lang::msg( 'sisysteminfo' ) ?>" ); 
tabs.addTab( "php-page","<?php echo ext_Lang::msg('siphpinfo' ); ?>" ); 
tabs.activate( "system-page" );
//-->
</script>
	<?php
}
?>