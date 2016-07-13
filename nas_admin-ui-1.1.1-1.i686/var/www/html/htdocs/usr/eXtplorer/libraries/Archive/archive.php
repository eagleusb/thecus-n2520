<?php
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
/**
 * @version		$Id: archive.php 9764 2007-12-30 07:48:11Z ircmaxell $
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
require_once dirname(__FILE__).'/../PEAR.php';
/**
 * An Archive handling class
 *
 * @static
 * @package 	Joomla.Framework
 * @subpackage	FileSystem
 * @since		1.5
 */
class extArchive {
	/**
	 * @param	string	The name of the archive file
	 * @param	string	Directory to unpack into
	 * @return	boolean	True for success
	 */
	function extract( $archivename, $extractdir ) {
		require_once( dirname(__FILE__). '/file.php' ) ;
		require_once( dirname(__FILE__). '/folder.php' ) ;

		$untar = false ;
		$result = false ;
		$ext = extFile::getExt( strtolower( $archivename ) ) ;
		// check if a tar is embedded...gzip/bzip2 can just be plain files!
		if( extFile::getExt( extFile::stripExt( strtolower( $archivename ) ) ) == 'tar' ) {
			$untar = true ;
		}
		
		switch( $ext) {
			case 'zip' :
				$adapter = & extArchive::getAdapter( 'zip' ) ;
				if( $adapter ) {
					$result = $adapter->extract( $archivename, $extractdir ) ;
				}
			break ;
			case 'tar' :
				$adapter = & extArchive::getAdapter( 'tar' ) ;
				if( $adapter ) {
					$result = $adapter->extract( $archivename, $extractdir ) ;
				}
			break ;
			case 'tgz' :
				$untar = true ; // This format is a tarball gzip'd
			case 'gz' : // This may just be an individual file (e.g. sql script)
			case 'gzip' :
				$adapter = & extArchive::getAdapter( 'gzip' ) ;
				if( $adapter ) {
					$tmpfname = (defined('_EXT_FTPTMP_PATH' ) ? _EXT_FTPTMP_PATH.'/' : $extractdir )  . uniqid( 'gzip' ) ;
					$gzresult = $adapter->extract( $archivename, $tmpfname ) ;
					if( !$gzresult ) {
						unlink( $tmpfname ) ;
						return false ;
					}
					if( $untar ) {
						// Try to untar the file
						$tadapter = & extArchive::getAdapter( 'tar' ) ;
						if( $tadapter ) {
							$result = $tadapter->extract( $tmpfname, $extractdir ) ;
						}
					} else {
						$path = extPath::clean( $extractdir ) ;
						mkdir( $path ) ;
						$result = copy( $tmpfname, $path . DS . extFile::stripExt( extFile::getName( strtolower( $archivename ) ) ) ) ;
					}
					@unlink( $tmpfname ) ;
				}
			break ;
			case 'tbz2' :
				$untar = true ; // This format is a tarball bzip2'd
			case 'bz2' : // This may just be an individual file (e.g. sql script)
			case 'bzip2' :
				$adapter = & extArchive::getAdapter( 'bzip2' ) ;
				if( $adapter ) {
					$tmpfname = _EXT_FTPTMP_PATH .'/' . uniqid( 'bzip2' ) ;
					$bzresult = $adapter->extract( $archivename, $tmpfname ) ;
					if( !$bzresult ) {
						@unlink( $tmpfname ) ;
						return false ;
					}
					if( $untar ) {
						// Try to untar the file
						$tadapter = & extArchive::getAdapter( 'tar' ) ;
						if( $tadapter ) {
							$result = $tadapter->extract( $tmpfname, $extractdir ) ;
						}
					} else {
						$path = extPath::clean( $extractdir ) ;
						mkdir( $path ) ;
						$result = copy( $tmpfname, $path . DS . extFile::stripExt( extFile::getName( strtolower( $archivename ) ) ) ) ;
					}
					@unlink( $tmpfname ) ;
				}
			break ;
			default :
				return PEAR::raiseError('Unknown Archive Type: '.$ext );
			break ;
		}
		return $result;
	}
	
	function &getAdapter( $type ) {
		static $adapters ;
		
		if( ! isset( $adapters ) ) {
			$adapters = array( ) ;
		}
		
		if( ! isset( $adapters[$type] ) ) {
			// Try to load the adapter object
			$class = 'extArchive' . ucfirst( $type ) ;
			
			if( ! class_exists( $class ) ) {
				$path = dirname( __FILE__ )  . '/adapter/' . strtolower( $type ) . '.php' ;
				if( file_exists( $path ) ) {
					require_once ($path) ;
				} else {
					echo 'Unknown Archive Type: '.$class;
					ext_Result::sendResult('archive', false, 'Unable to load archive' ) ;
				}
			}
			
			$adapters[$type] = new $class( ) ;
		}
		return $adapters[$type] ;
	}
	
	/**
	 * @param	string	The name of the archive
	 * @param	mixed	The name of a single file or an array of files
	 * @param	string	The compression for the archive
	 * @param	string	Path to add within the archive
	 * @param	string	Path to remove within the archive
	 * @param	boolean	Automatically append the extension for the archive
	 * @param	boolean	Remove for source files
	 */
	function create( $archive, $files, $compress = 'tar', $addPath = '', $removePath = '', $autoExt = false, $cleanUp = false ) {
		$compress = strtolower( $compress );
		if( $compress == 'tgz' || $compress == 'tbz' || $compress == 'tar') {
			require_once( _EXT_PATH.'/libraries/Tar.php' ) ;
			
			if( is_string( $files ) ) {
				$files = array( $files ) ;
			}
			if( $autoExt ) {
				$archive .= '.' . $compress ;
			}
			if( $compress == 'tgz'  ) $compress = 'gz';
			if( $compress == 'tbz'  ) $compress = 'bz2';
			
			$tar = new Archive_Tar( $archive, $compress ) ;
			$tar->setErrorHandling( PEAR_ERROR_PRINT ) ;
			$result = $tar->addModify( $files, $addPath, $removePath ) ;
			
			return $result;
		}
		if( $compress == 'zip' ) {
			/*require_once( _EXT_PATH.'/libraries/lib_zip.php' );
			$zip = new ZipFile();
			$zip->addFileList($files, $removePath );
			return $zip->save($archive);
			*/
			
			require_once( _EXT_PATH.'/libraries/Zip.php' );
			$zip = new Archive_Zip( $archive ) ;
			$result = $zip->add( $files, array( 'add_path' => $addPath, 'remove_path' => $removePath) ) ;
			
			/*require_once( _EXT_PATH.'/libraries/pclzip.lib.php' );
			$zip = new PclZip($archive);
			$result = $zip->add($files, PCLZIP_OPT_ADD_PATH, $addPath, PCLZIP_OPT_REMOVE_PATH, $removePath );
			*/
			if($result == 0) {
				return new PEAR_Error( 'Unrecoverable error "'.$zip->errorInfo(true).'"' );
			}
		}
	}
}