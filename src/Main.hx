
import xmpp.Jid;

function main() {

    var _jid = Sys.getEnv('INPUT_JID');
    if(_jid == null) abort('missing jid');
    var jid : Jid = _jid;
    var password = Sys.getEnv('INPUT_PASSWORD');
    var recipient = Sys.getEnv('INPUT_RECIPIENT');
    var message = Sys.getEnv('INPUT_MESSAGE');
    var host = Sys.getEnv('INPUT_HOST');
    var _port = Sys.getEnv('INPUT_PORT');
    var port : Int = (_port != null) ? Std.parseInt(_port) : xmpp.client.Stream.PORT;
    var _muc = Sys.getEnv('INPUT_MUC');
    var logoutDelay = 3000;//TODO:

    if(password == null) abort('missing password');
    if(message == null) abort('missing message');

    if(host == null || host.length == 0) host = jid.domain;

    var xmpp = new XmppClient();
    xmpp.login(jid, password, host, port, e -> {
        if(e == null){
            //Sys.println("Connected");
            //xmpp.stream.send(new Presence());
            if(recipient != null) {
              xmpp.notifyUser(recipient, message);
            }
            if(Jid.isValid(_muc)) {
              final mucjid : Jid = _muc;
              xmpp.notifyChat(mucjid, message);
            }
            haxe.Timer.delay(xmpp.logout, logoutDelay);
        } else {
            abort(e);
        }
    });
}

function abort(code = 1, ?message: String) {
    if( message != null) Sys.stderr().writeString('$message\n');
    Sys.exit(code);
}
