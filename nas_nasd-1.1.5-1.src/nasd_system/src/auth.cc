#include <pwd.h>
#include <shadow.h>
#include <sys/types.h>
#include <unistd.h>

#include <node.h>
#include <v8.h>

using namespace v8;

static bool auth(char *username, char *password)
{
    char *shadow, *salt, *encrypt;
    struct spwd *shadow_entry;
    
    shadow_entry = getspnam(username);
    
    if (shadow_entry == NULL) {
        return false;
    }
    shadow = shadow_entry->sp_pwdp;
    salt = strdup(shadow);
    if (salt == NULL) {
        return false;
    }
    
    if (strchr(salt + 1, '$') == NULL) {
        return false;
    }
    
    encrypt = crypt(password, salt);
    if (encrypt == NULL) {
        return false;
    }
    
    return strcmp(shadow, encrypt) == 0;
}

Handle<Value> auth(const Arguments& args) {
    HandleScope scope;
    
    if (args.Length() < 2) {
        ThrowException(Exception::TypeError(String::New("Wrong number of arguments")));
        return scope.Close(Boolean::New(false));
    }
    
    if (!args[0]->IsString() || !args[1]->IsString()) {
        ThrowException(Exception::TypeError(String::New("Wrong arguments")));
        return scope.Close(Boolean::New(false));
    }
    
    String::AsciiValue username(args[0]);
    String::AsciiValue password(args[1]);
    
    bool vaild = auth(*username, *password);
    
    return scope.Close(Boolean::New(vaild));
}

extern "C" void NODE_EXTERN init (Handle<Object> target) {
    target->Set(
        String::NewSymbol("auth"),
        FunctionTemplate::New(auth)->GetFunction()
    );
}

NODE_MODULE(system, init)
