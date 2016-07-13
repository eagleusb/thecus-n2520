#!/usr/bin/env node

(require('Nasd'))(function (Nasd) {
    Nasd.USB.copy(function (result) {
        if (result) {
            console.info('USB backup is on going');
        } else {
            console.info('Another process is on going');
        }
        Nasd.destroy();
    });
});
