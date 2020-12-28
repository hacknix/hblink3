from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor, task
from time import time


class Proxy(DatagramProtocol):

    def __init__(self,ListenPort,connTrack,Timeout,Debug):
        self.connTrack = connTrack
        self.sourceTrack = {}
        self.timeout = Timeout
        self.debug = Debug

    def datagramReceived(self, data, addr):
        host,port = addr
        
        nowtime = time()
        
        Debug = self.debug
        
        #If the packet comes from the master
        if host == '127.0.0.1' and port in self.connTrack:
            if int(self.connTrack[port]['time'])+self.timeout >nowtime:
                self.transport.write(data,(self.connTrack[port]['host'],self.connTrack[port]['sport']))
                if Debug:
                    print("return path match")
                    print(data)
            elif self.sourceTrack[str(self.connTrack[port]['host'])+":"+str(self.connTrack[port]['sport'])] in self.sourceTrack:
                del self.sourceTrack[str(self.connTrack[port]['host'])+":"+str(self.connTrack[port]['sport'])]
            return
        
            #If we have a sourcetrack for this connect and thenowtimeout has not expired, forward to tracked port
        if host+":"+str(port) in self.sourceTrack and (int(self.sourceTrack[host+":"+str(port)]['time'])+self.timeout >nowtime):
            self.transport.write(data, ('127.0.0.1',self.sourceTrack[host+":"+str(port)]['dport']))
            self.connTrack[self.sourceTrack[host+":"+str(port)]['dport']]['time'] =nowtime
            self.sourceTrack[host+":"+str(port)]['time'] =nowtime
            if Debug:
                print("Tracked inbound match")
                print(data)
            return
        elif host+":"+str(port) in self.sourceTrack:
            del self.sourceTrack[host+":"+str(port)]
        
        #Find free port to map for new connection
        for dport in self.connTrack:
            if (self.connTrack[dport]['time'] == False or (int(self.connTrack[dport]['time'])+self.timeout < nowtime)):
                self.connTrack[dport]['sport'] = port
                self.connTrack[dport]['host'] = host
                self.connTrack[dport]['time'] =nowtime
                self.sourceTrack[host+":"+str(port)] = {}
                self.sourceTrack[host+":"+str(port)]['dport'] = dport
                self.sourceTrack[host+":"+str(port)]['time'] = nowtime
                self.transport.write(data, ('127.0.0.1',dport))
                if Debug:
                    print("New connection")
                    print(data)
                return
     


if __name__ == '__main__':

#*** CONFIG HERE ***
    
    ListenPort = 62031
    DestportStart = 54001
    DestPortEnd = 54002
    Timeout = 35
    Stats = True
    Debug = True
    
#*******************

    
    CONNTRACK = {}

    for port in range(DestportStart,DestPortEnd,1):
        CONNTRACK[port] = {'host': False,'time': False,'sport':False, 'nacktime': False}

    reactor.listenUDP(ListenPort,Proxy(ListenPort,CONNTRACK,Timeout,Debug))

    def loopingErrHandle(failure):
        print('(GLOBAL) STOPPING REACTOR TO AVOID MEMORY LEAK: Unhandled error innowtimed loop.\n {}'.format(failure))
        reactor.stop()
        
    def stats():        
        count = 0
        nowtime = time()
        for port in CONNTRACK:
            if int(CONNTRACK[port]['time'])+Timeout > nowtime:
                count = count+1
                
        totalPorts = DestPortEnd - DestportStart
        freePorts = totalPorts - count
        
        print("{} ports out of {} in use ({} free)".format(count,totalPorts,freePorts))


        
    if Stats == True:
        stats_task = task.LoopingCall(stats)
        statsa = stats_task.start(30)
        statsa.addErrback(loopingErrHandle)

    reactor.run()
    
