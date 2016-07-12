#!/usr/bin/env node

function Hardware() {
    var THECUS_IO = '/proc/thecus_io';
    var fs = require('fs');
    
    function echo(val) {
        fs.appendFileSync(THECUS_IO, val, 'utf8');
    }
    
    var u_led = {
        off: function () {
            echo('U_LED 0');
        },
        on: function () {
            echo('U_LED 1');
        },
        blink: function () {
            echo('U_LED 2');
        }
    };
    
    var sd_led = {
        off: function () {
            echo('SD_LED 0');
        },
        on: function () {
            echo('SD_LED 1');
        },
        blink: function () {
            echo('SD_LED 2');
        }
    };
    
    var uf_led = {
        off: function () {
            echo('UF_LED 0');
        },
        on: function () {
            echo('UF_LED 1');
        },
        blink: function () {
            echo('UF_LED 2');
        }
    };

    var sdf_led = {
        off: function () {
            echo('SDF_LED 0');
        },
        on: function () {
            echo('SDF_LED 1');
        },
        blink: function () {
            echo('SDF_LED 2');
        }
    };

    var buzz = {
        off: function () {
            echo('Buzzer 0');
        },
        on: function () {
            echo('Buzzer 1');
        }
    };

    var lcm_btn_press = {
        up: function () {
            echo ('BTN_OP 1');
        },
        down: function () {
            echo ('BTN_OP 2');
        },
        enter: function () {
            echo ('BTN_OP 3');
        },
        esc: function () {
            echo ('BTN_OP 4');
        }
	};
    
    return {
        led: {
            u: u_led,
            sd: sd_led,
            uf: uf_led,
            sdf: sdf_led,
            off: function () {
                u_led.off();
                sd_led.off();
                uf_led.off();
                sdf_led.off();
            },
            on: function () {
                u_led.on();
                sd_led.on();
                uf_led.on();
                sdf_led.on();
            },
            blink: function () {
                u_led.blink();
                sd_led.blink();
                uf_led.blink();
                sdf_led.blink();
            }
        },
        buzzer: buzz,
        lcm: {
            press: lcm_btn_press
        }
    }
}
inherits(Hardware, events.EventEmitter);

module.exports = new Hardware();
