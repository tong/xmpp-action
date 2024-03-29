
import js.Node.console;
import js.node.net.Socket;
import js.node.tls.TLSSocket;
import xmpp.IQ;
import xmpp.Jid;
import xmpp.Message;
import xmpp.Presence;
import xmpp.Response;
import xmpp.Stream;
import xmpp.XML;
import xmpp.client.Stream;

using xmpp.StartTLS;
using xmpp.client.Authentication;

class XmppClient {

	static function print( str : String, ?color : Int ) {
		if( color != null ) str = '\x1B['+color+'m'+str+'\x1B[0m';
		Sys.println(str);
	}

	public var jid(default,null) : Jid;

    var stream : Stream;
	var socket : Socket;
	var tls : TLSSocket;

	public function new() {}

	public function login(jid: Jid, password: String, host: String, port: Int, callback: String->Void) {

		function sendData(str:String) {
            #if xmpp_debug
			print( xmpp.xml.Printer.print(str,true), 32 );
            #end
			socket.write( str );
		};

		function recvData(buf) {
			var str : String = #if nodejs buf.toString() #else buf #end;
            #if xmpp_debug
			print( xmpp.xml.Printer.print( str, true ), 33 );
            #end
			stream.recv( str );
		}

		socket = new Socket();
		socket.on( 'data', recvData );
		socket.on( 'end', () -> console.log('Socket disconnected') );
		socket.on( 'error', e -> console.error('Socket error',e) );

		stream = new Stream( jid.domain );
        stream.onEnd = () -> socket.end();
		//stream.onPresence = p -> console.log( 'Presence from: '+p.from );
		//stream.onMessage = m -> console.log( 'Message from: '+m.from );
		stream.onIQ = (iq,res) -> {
			console.warn( 'Unhandled iq: '+iq );
		}

		stream.output = sendData;

		socket.connect(port, host, () -> {
			stream.start( features->{
				stream.startTLS(success->{
					if( success ) {
						var tls = new js.node.tls.TLSSocket(socket, { requestCert: true, rejectUnauthorized: true });
						//tls.on('end', ()->console.log('TLSSocket disconnected'));
						tls.on('error', e->console.error('TLSSocket error',e));
						tls.on('data', recvData);
						socket = tls;
						stream.start(features->{
							var mech = new sasl.SCRAMSHA1Mechanism();
							stream.authenticate(jid.node, jid.resource, password, mech, (?error)->{
								if(error != null) {
									console.error(error.condition, error.text);
									stream.end();
									socket.end();
								} else {
                                    callback(null);
								}
							});
						});
					} else {
						console.error("StartTLS failed");
						socket.end();
					}
				});
			});
		});
	}

    public function logout() {
        stream.end();
    }

    public function notifyUser(jid: Jid, message:String) {
      stream.send(new Message(jid, message));
    }

    public function notifyChat(jid: Jid, message:String) {
      final muc = new xmpp.Muc(stream, jid.domain, jid.node);
      muc.join(jid.resource, res->{
        switch res {
        case Result(r):
          muc.say(message);
          //muc.leave();
        case Error(e): 
          trace('Failed to join [${muc.jid}]: '+e);
        }
      });
    }
}
