import subprocess
import sys
import socket

def get_limit(delay, rate, qdelay, burst=None, hz=100, pkt_size=1500, min_burst=10000):
    #we need min_burst, less than it will not achieve the idea throughput for tcp
    netem_qsize = delay*rate/8000
    if burst is None:
        tbf_burst = max(rate/8/hz, min_burst)#the burst can be adjust up for allowing more burst
    else:
        tbf_burst = max(burst, min_burst, rate/8/hz)
    tbf_qsize = qdelay*rate/8000
 
    #tbf_limit = tbf_burst + netem_qsize + tbf_qsize
    tbf_limit = netem_qsize + tbf_qsize
    pkt_limit = max(2,(tbf_limit + pkt_size -1)/pkt_size) #the pkt limit should be larger than this one
    #logger.debug('netem_buffer: %d, tbf_buffer: %d, tbf_burst:%d'%(netem_buffer, tbf_buffer, tbf_burst))
    #logger.debug('tbf_limit: %d, pkt_limit: %d'%(tbf_limit, pkt_limit))
    return {'netem_qsize':netem_qsize,
            'tbf_qsize':tbf_qsize,
            'tbf_burst':tbf_burst,
            'tbf_limit':tbf_limit,
            'pkt_limit':pkt_limit,}    

def exec_cmds(cmd_str):
    for cmd in cmd_str.split(';'):
        if cmd is '': return
        print cmd
        #continue
        p = subprocess.Popen(cmd.split(), bufsize=-1,
                            stdout=subprocess.PIPE,
                            stdin=subprocess.PIPE,
                            stderr=subprocess.PIPE)
        result = p.communicate()
        if result[1] != '':
            print result

################ ifb ##############

def ifb_up():
    enable_cmd = '''modprobe ifb;\
ip link set dev ifb0 up'''
    exec_cmds(enable_cmd)

def ifb_down():
    disable_cmd = '''ip link set dev ifb0 down;\
modprobe -r ifb'''
    exec_cmds(disable_cmd)

################ policer #############

def enable_policer(rate, burst, delay, loss):
    enable_cmd = '''tc qdisc add dev eth0 ingress;\
tc filter add dev eth0 parent ffff: protocol ip prio 20 u32 match ip dst 0.0.0.0/0 police rate %d burst %d drop flowid :1;\
tc qdisc add dev eth0 root handle 1:0 netem delay %dms loss %f%%'''%(rate, burst, delay, loss)

    exec_cmds(enable_cmd)

def disable_policer():
    disable_cmd = 'tc qdisc del dev eth0 ingress;tc qdisc del dev eth0 root'
    exec_cmds(disable_cmd)
           
################ shaper ##############
#tc qdisc add dev eth0 root handle 1: tbf rate %d burst %d latency 1ms;\
#tc qdisc add dev eth0 parent 1:0 handle 10:1 pfifo limit %d;\
#tc filter add dev eth0 parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ifb0;\

def enable_shaper_tbf(rate, burst, delay, pktlimit, loss):
    ifb_up()
    #20ms distribution normal
    enable_cmd = '''tc qdisc add dev eth0 ingress;\
tc filter add dev eth0 parent ffff: protocol ip u32 match ip dst %s flowid 1:1 action mirred egress redirect dev ifb0;\
tc qdisc add dev ifb0 root netem delay %dms loss %f%%;\
tc qdisc add dev eth0 root handle 1: tbf rate %d burst %d latency 1ms;\
tc qdisc add dev eth0 parent 1:0 handle 10:1 pfifo limit %d'''%(RECEIVER_IP, delay, loss, rate, burst, pktlimit)

    exec_cmds(enable_cmd) 


def enable_shaper_htb(rate, burst, delay, pktlimit, loss):
    ifb_up()
    #20ms distribution normal
    enable_cmd = '''tc qdisc add dev eth0 ingress;\
tc filter add dev eth0 parent ffff: protocol ip u32 match ip dst %s flowid 1:1 action mirred egress redirect dev ifb0;\
tc qdisc add dev ifb0 root netem delay %dms loss %f%%;\
tc qdisc add dev eth0 root handle 1: htb default 10;\
tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbps ceil 1000mbps;\
tc class add dev eth0 parent 1:1 classid 1:10 htb rate %d burst %d ceil %d cburst %d;\
tc qdisc add dev eth0 parent 1:10 handle 10: pfifo limit %d;\
tc class add dev eth0 parent 1:1 classid 1:12 htb rate %d ceil 1000mbps;\
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst %s flowid 1:10''' % \
(RECEIVER_IP, delay, loss, rate, burst, rate, burst, pktlimit, 1000000000-rate, RECEIVER_IP)

    exec_cmds(enable_cmd) 
    
def disable_shaper():
    disable_cmd = '''tc qdisc del dev eth0 root;\
tc qdisc del dev eth0 ingress;\
tc qdisc del dev ifb0 root'''

    exec_cmds(disable_cmd)
    ifb_down()

def start():
    rate = 1000000
    qdelay = 1000
    delay = 100
    burst = 30000 #set to None to use the cacluated one
    #burst = None #burst is sometimes needed if want to achive TCP max throughput, becuase tcp is window-based and has burst
    loss = 0 #5 means 5%

    dict = get_limit(0, rate, qdelay, burst) # because we separte netem with tbf, so don't count netem buffer here.
    print dict
    #enable_shaper_tbf(rate, dict['tbf_burst'], delay, dict['pkt_limit'], loss)
    enable_shaper_htb(rate, dict['tbf_burst'], delay, dict['pkt_limit'], loss)
    #enable_policer(rate, dict['tbf_burst'], delay, loss)

def stop():
    disable_shaper()
    disable_policer()

if __name__ == '__main__':

    if len(sys.argv) == 2:
        if sys.argv[1] == 'start':
            start()
        elif sys.argv[1] == 'stop':
            stop()
        elif sys.argv[1] == 'restart':
            stop()
            start()
