<?php
/**
 * @version		$Id:bzip2.php 6961 2007-03-15 16:06:53Z tcp $
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
 * Bzip2 format adapter for the JArchive class
 *
 * @author		Louis Landry <louis.landry@joomla.org>
 * @package 	Joomla.Framework
 * @subpackage	FileSystem
 * @since		1.5
 */
class extArchiveBzip2 {
	/**
	 * Bzip2 file data buffer
	 * @var string
	 */
	var $_data = null ;
	
	/**
	 * Constructor tries to load the bz2 extension of not loaded
	 *
	 * @access	protected
	 * @return	void
	 * @since	1.5
	 */
	function __construct() {
		// Is bz2 extension loaded?  If not try to load it
		if( ! extension_loaded( 'bz2' ) ) {
			if( EXTPATH_ISWIN ) {
				@ dl( 'php_bz2.dll' ) ;
			} else {
				@ dl( 'bz2.so' ) ;
			}
		}
	}
	
	/**
	 * Extract a Bzip2 compressed file to a given path
	 *
	 * @access	public
	 * @param	string	$archive		Path to Bzip2 archive to extract
	 * @param	string	$destination	Path to extract archive to
	 * @param	array	$options		Extraction options [unused]
	 * @return	boolean	True if successful
	 * @since	1.5
	 */
	function extract( $archive, $destination, $options = array () ) {
		// Initialize variables
		$this->_data = null ;
		
		if( ! extension_loaded( 'bz2' ) ) {
			return PEAR::raiseError( 'BZip2 Not Supported' ) ;
		}
		
		if( ! $this->_data = JFile::read( $archive ) ) {
			return PEAR::raiseError( 'Unable to read archive' ) ;
		}
		
		$buffer = bzdecompress( $this->_data ) ;
		if( empty( $buffer ) ) {
			return PEAR::raiseError( 'Unable to decompress data' ) ;
		}
		
		if( JFile::write( $destination, $buffer ) === false ) {
			return PEAR::raiseError( 'Unable to write archive' ) ;
		}
		return true ;
	}
}
?>