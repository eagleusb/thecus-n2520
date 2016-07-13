<?php
abstract class Commander {
    /**
     *  This background method just execute shell command and avoid to get result from it.
     * 
     *  @param args All arguments will be combined as a shell command via PHP sprintf().
     *  @return NULL
     */
    static function background() {
        $args = func_get_args();
        $cmd = call_user_func_array(sprintf, $args);
        $pwd = getcwd();
        chdir("/tmp");
        shell_exec($cmd);
        chdir($pwd);
    }
    
    /**
     *  This frontground method will run shell command and return some value.
     * 
     *  @param $type 'A'rray, 'B'oolean, 'D'ouble, 'I'nteger, 'S'tring, and NULL can be accepted.
     *  @param $cmd A shell command can be format as well as PHP sprintf().
     *  @param $args All arguments for shell command.
     *  @return $mixed The return value will format as $type requirement.
     */
    static function frontground($type = 's', $cmd) {
        $args = func_get_args();
        $type = array_shift($args);
        $cmd = call_user_func_array(sprintf, $args);
        
        $pp = popen($cmd, 'r');
        switch($type) {
        case NULL:
            break;
        case 'a':
        case 'A':
            $result = array();
            while(!feof($pp)) {
                array_push($result, trim(fgets($pp)));
            }
            break;
        case 'b':
        case 'B':
            $result = (bool)fgets($pp);
            break;
        case 'd':
        case 'D':
            $result = (double)fgets($pp);
            break;
        case 'i':
        case 'I':
            $result = (int)fgets($pp);
            break;
        case 's':
        case 'S':
        default:
            $result = trim(fgets($pp));
            break;
        }
        pclose($pp);
        return $result;
    }
    
    static function fg() {
        $args = func_get_args();
        return call_user_func_array( array(self, 'frontground'), &$args);
    }
    
    static function bg() {
        $args = func_get_args();
        call_user_func_array( array(self, 'background'), &$args);
    }
}
?>
