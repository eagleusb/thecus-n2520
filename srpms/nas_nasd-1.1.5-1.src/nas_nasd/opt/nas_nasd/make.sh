#!/usr/bin

export PATH=/usr/lib/ccache:/sbin:/bin:/usr/sbin:/usr/bin:/usr/lib/node_modules/npm/bin/node-gyp-bin

# node_modules/socket.io/node_modules/socket.io-client/node_modules/ws
pushd node_modules/socket.io/node_modules/socket.io-client/node_modules/ws
node-gyp rebuild
strip build/Release/*.node
mv build/Release/*.node .
rm -rf build binding.gyp src
mkdir -p build/Release
mv *.node build/Release
popd

# node_modules/socket.io/node_modules/redis/node_modules/hiredis
pushd node_modules/socket.io/node_modules/redis/node_modules/hiredis
make
strip build/Release/*.node
mv build/Release/*.node .
rm -rf *.cc *.h bench.js .lock-wscript build Makefile wscript deps
mkdir -p build/Release
mv *.node build/Release
popd


# node_modules/sqlite3
pushd node_modules/sqlite3
node-gyp rebuild
strip build/Release/*.node
mv build/Release/*.node .
rm -rf build binding.gyp src deps
mkdir -p build/Release
mv *.node build/Release
popd

# Build nasd services
find service/ -name binding.gyp | while read line; do
    path=`echo $line | sed  "s/[^\/]*$//g"`
    pushd $path
        node-gyp rebuild
        strip build/Release/*.node
        mv build/Release/*.node .
        rm -rf build binding.gyp *.md src
        mkdir -p build/Release
        mv *.node build/Release
    popd
done

rm -rf `find service | grep -E "\.(md|cc?|h)$|binding.gyp"`
rm -f `find . -name ".gitignore"`


# Remove develope resources
rm -f README.md yuidoc.json

