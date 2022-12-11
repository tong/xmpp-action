
import xmpp.JID;
import xmpp.Presence;
import xmpp.Message;

function main() {

    var args = Sys.args();
    if( args.length < 2 ) {
        Sys.stderr().writeString( 'Invalid arguments\n' );
        Sys.println( '  Usage: xmpp <jid> <password> <?ip>' );
        Sys.exit(1);
    }

    var jid : JID = args[0];
    if( jid.resource == null ) jid.resource = 'hxmpp';
    var password = args[1];
    var ip = (args[2] == null) ? jid.domain : args[2];
    
    var receiver = "tong@x.disktree.net";
    var subject = null;
    var body = "hello!";

    var xmpp = new XmppClient();
    xmpp.login( jid, password, ip, e -> {
        if(e == null){
            Sys.println("Client connected");
            xmpp.stream.send(new Presence());
            xmpp.stream.send(new Message(receiver, body, subject));
        } else {
            Sys.stderr().writeString(e);
            Sys.exit(1); 
        }
    });
}
