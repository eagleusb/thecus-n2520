<?php
/**
 * @version		$Id:gzip.php 6961 2007-03-15 16:06:53Z tcp $
 * @package		Joomla.Framework
 * @subpackage	FileSystem
 * @copyright	Copyright (C) 2005 - 2008 Open Source Matters. All rights reserved.
 * @license		GNU/GPL, see LICENSE.php
 * Joomla! is free software. This version may have been modified pursuant
 * to the GNU General Public License, and as distributed it includes or
 * is derivative of works licensed under the GNU General Public License or
 * other free or open source software licenses.
 * See COPYRIGHT.php for copyright notices and details.
 */

// Check to ensure this file is within the rest of the framework
if( ! defined( '_JEXEC' ) && ! defined( '_VALID_MOS' ) )
	die( 'Restricted access' ) ;

/**
 * Gzip format adapter for the JArchive class
 *
 * This class is inspired from and draws heavily in code and concept from the Compress package of
 * The Horde Project <http://www.horde.org>
 *
 * @contributor  Michael Slusarz <slusarz@horde.org>
 * @contributor  Michael Cochrane <mike@graftonhall.co.nz>
 *
 * @author		Louis Landry <louis.landry@joomla.org>
 * @package 	Joomla.Framework
 * @subpackage	FileSystem
 * @since		1.5
 */
class extArchiveGzip {
	/**
	 * Gzip file flags.
	 * @var array
	 */
	var $_flags = array( 'FTEXT' => 0x01 , 'FHCRC' => 0x02 , 'FEXTRA' => 0x04 , 'FNAME' => 0x08 , 'FCOMMENT' => 0x10 ) ;
	
	/**
	 * Gzip file data buffer
	 * @var string
	 */
	var $_data = null ;
	
	/**
	 * Extract a Gzip compressed file to a given path
	 *
	 * @access	public
	 * @param	string	$archive		Path to ZIP archive to extract
	 * @param	string	$destination	Path to extract archive to
	 * @param	array	$options		Extraction options [unused]
	 * @return	boolean	True if successful
	 * @since	1.5
	 */
	function extract( $archive, $destination, $options = array () ) {
		// Initialize variables
		$this->_data = null ;
		
		if( ! extension_loaded( 'zlib' ) ) {
			return PEAR::raiseError( 'Zlib Not Supported' ) ;
		}
		$this->_data = file_get_contents( $archive );
		if( !$this->_data ) {
			return PEAR::raiseError( 'Unable to read archive' ) ;
		}
		
		$position = $this->_getFilePosition() ;
		
		$buffer = gzinflate( substr( $this->_data, $position, strlen( $this->_data ) - $position ) ) ;
		if( empty( $buffer ) ) {
			return PEAR::raiseError( 'Unable to decompress data' ) ;
		}
		
		if( file_put_contents( $destination, $buffer ) === false ) {
			return PEAR::raiseError( 'Unable to write archive' ) ;
		}
		return true ;
	}
	
	/**
	 * Get file data offset for archive
	 *
	 * @access	public
	 * @return	int	Data position marker for archive
	 * @since	1.5
	 */
	function _getFilePosition() {
		// gzipped file... unpack it first
		$position = 0 ;
		$info = @ unpack( 'CCM/CFLG/VTime/CXFL/COS', substr( $this->_data, $position + 2 ) ) ;
		if( ! $info ) {
			return PEAR::raiseError( 'Unable to decompress data' ) ;
		}
		$position += 10 ;
		
		if( $info['FLG'] & $this->_flags['FEXTRA'] ) {
			$XLEN = unpack( 'vLength', substr( $this->_data, $position + 0, 2 ) ) ;
			$XLEN = $XLEN['Length'] ;
			$position += $XLEN + 2 ;
		}
		
		if( $info['FLG'] & $this->_flags['FNAME'] ) {
			$filenamePos = strpos( $this->_data, "\x0", $position ) ;
			$filename = substr( $this->_data, $position, $filenamePos - $position ) ;
			$position = $filenamePos + 1 ;
		}
		
		if( $info['FLG'] & $this->_flags['FCOMMENT'] ) {
			$commentPos = strpos( $this->_data, "\x0", $position ) ;
			$comment = substr( $this->_data, $position, $commentPos - $position ) ;
			$position = $commentPos + 1 ;
		}
		
		if( $info['FLG'] & $this->_flags['FHCRC'] ) {
			$hcrc = unpack( 'vCRC', substr( $this->_data, $position + 0, 2 ) ) ;
			$hcrc = $hcrc['CRC'] ;
			$position += 2 ;
		}
		
		return $position ;
	}
}
?>