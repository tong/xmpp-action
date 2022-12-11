
import xmpp.JID;
import xmpp.IQ;
import xmpp.Message;
import xmpp.Presence;
import xmpp.Stream;
import xmpp.client.Stream;
import xmpp.XML;
import js.node.net.Socket;
import js.node.tls.TLSSocket;

using xmpp.client.Authentication;
using xmpp.client.StartTLS;
using xmpp.client.Roster;

class XmppClient {

	static function print( str : String, ?color : Int ) {
		if( color != null ) str = '\x1B['+color+'m'+str+'\x1B[0m';
		Sys.println(str);
	}

	public var jid(default,null) : JID;
	public var stream(default,null) : Stream;

	var socket : Socket;
	var tls : TLSSocket;

	public function new() {
    }

	public function login(jid: JID, password: String, ?ip : String, callback : String->Void ) {

		if( ip == null ) ip = jid.domain;

		function sendData(str:String) {
			print( xmpp.xml.Printer.print(str,true), 32 );
			socket.write( str );
		};

		function recvData(buf) {
			var str : String = #if nodejs buf.toString() #else buf #end;
			print( xmpp.xml.Printer.print( str, true ), 33 );
			stream.recv( str );
		}

		socket = new Socket();
		socket.on( Data, recvData );
		socket.on( End, () -> trace('Socket disconnected') );
		socket.on( Error, e -> trace('Socket error',e) );

		stream = new Stream( jid.domain );
		stream.onPresence = p -> trace( 'Presence from: '+p.from );
		stream.onMessage = m -> trace( 'Message from: '+m.from );
		stream.onIQ = iq -> {
			trace( 'Unhandled iq: '+iq );
		}

		stream.output = sendData;

		socket.connect( xmpp.client.Stream.PORT, ip, function() {
			stream.start( features->{
				trace(features);
				stream.startTLS(success->{
					if( success ) {
						var tls = new js.node.tls.TLSSocket(socket, { requestCert: true, rejectUnauthorized: true });
						tls.on(End, ()->trace('TLSSocket disconnected'));
						tls.on(Error, e->trace('TLSSocket error',e));
						tls.on(Data, recvData);
						socket = tls;
						stream.start(features->{
							for(f in features.elements) trace(f);
							var mech = new sasl.PlainMechanism(false);
							//var mech = new sasl.AnonymousMechanism();
							//var mech = new sasl.SCRAMSHA1Mechanism();
							stream.authenticate(jid.node, jid.resource, password, mech, (?error)->{
								if(error != null) {
									trace(error.condition, error.text);
									stream.end();
									socket.end();
								} else {
                                    callback(null);
								}
							});
						});
					} else {
						trace("StartTLS failed");
						socket.end();
					}
				});
			});
		});
	}
}
