
import xmpp.JID;
import xmpp.Presence;
import xmpp.Message;

function abort(code = 1, ?message: String) {
    if( message != null) Sys.stderr().writeString('$message\n');
    Sys.exit(code);
}

function main() {
    
    var _jid = Sys.getEnv('INPUT_JID');
    if(_jid == null) abort('missing jid');
   
    var jid : JID = _jid;
    var password = Sys.getEnv('INPUT_PASSWORD');
    var recipient = Sys.getEnv('INPUT_RECIPIENT');
    var message = Sys.getEnv('INPUT_MESSAGE');
    var host = Sys.getEnv('INPUT_HOST');
   
    if(password == null) abort('missing password');
    if(recipient == null) abort('missing recipient');
    if(message == null) abort('missing message');
    if(host == null) host = jid.domain;
   
    var xmpp = new XmppClient();
    xmpp.login( jid, password, host, e -> {
        if(e == null){
            Sys.println("Client connected");
            xmpp.stream.send(new Presence());
            xmpp.stream.send(new Message(recipient, message));
        } else {
            Sys.stderr().writeString(e);
            Sys.exit(1); 
        }
    });
}
