<?php
// The following methods exist in /img/www/inc/rpc.class.php
abstract class RPC {
    static protected function fireEvent() {
        return func_get_args();
    }
}
?>
