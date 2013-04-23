
import java.io.IOException;

import com.ericsson.otp.erlang.*;

public class Test {

	public static void main(String [ ] args)
	{
		try {
			OtpNode node = new OtpNode("java");
			OtpMbox mbox = node.createMbox("j");
			System.out.println("host "+node.host() + " name " + node.node());
			System.out.println("init");
			/* <=> OtpMbox mbox = node.createMbox();
			 * mbox.registerName("server");
			 */
			System.out.println("main loop");
			while(true)
			{
				try {
					OtpErlangObject reply = mbox.receive();
					System.out.println("received msg");
					if(reply instanceof OtpErlangTuple)
					{
						OtpErlangTuple msg = (OtpErlangTuple) reply;
						OtpErlangPid pid = (OtpErlangPid) msg.elementAt(1);
						if(msg.elementAt(1).equals("ping"))
						{
							System.out.println(msg.elementAt(0).toString());
							mbox.send(pid,new OtpErlangAtom("poong"));
						}
					}
				} catch (OtpErlangExit e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (OtpErlangDecodeException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}
}
