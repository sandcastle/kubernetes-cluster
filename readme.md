#  Boostrapping Kubernetes on AWS
> Bootstraps a multi-node Kubernetes cluster on AWS


## Getting Started

To create a new cluster run the `init.sh` script in the root of the repo. If you 
dont have the AWS CLI installed, see below first.

```
sh init.sh
```


## AWS CLI
Before creating a cluster, you first need to install the AWS CLI locally,
you can find out more information [here](https://aws.amazon.com/cli/).

### Install

#### OSX
If you have [Homebrew](http://brew.sh/) installed, you can run the following command:

```sh
brew install awscli
```

#### Windows
If you have [Chocolatey](https://chocolatey.org) installed, you can run the following command:

```
choco install awscli
```

### Credentials
Once you have the AWS CLI install, you will need to configure it using the following command:

```sh
aws configure
```

## Production Ready
Before moving production load onto the cluster, please consider the following:

- Disable IGW routing to private subnet, see subnets section in `lib/network.sh` to configure


## Further Reading
Some articles that helped with this project:

- [Kubernetes Cluster on CoreOS - v1.0](https://github.com/kubernetes/kubernetes/blob/release-1.0/docs/getting-started-guides/coreos/coreos_multinode_cluster.md)
- [CoreOS on AWS](https://coreos.com/os/docs/latest/booting-on-ec2.html)
- [VPC reference architecture](http://blog.bwhaley.com/reference-vpc-architecture)
- [Zero downtime deployments](http://waytothepiratecove.blogspot.com.au/2015/03/delivery-pipeline-and-zero-downtime.html)

Some articles yet to be read that may provide value:

- [Some notes playing with HAProxy *](https://ymichael.com/2015/06/06/some-notes-playing-with-haproxy.html)
- [CoreOS follow-up: Sinatra, Logstash, Elasticsearch, and Kibana *](http://marceldegraaf.net/2014/05/05/coreos-follow-up-sinatra-logstash-elasticsearch-kibana.html)
- [Load-balancing Websockets on EC2](https://medium.com/@Philmod/load-balancing-websockets-on-ec2-1da94584a5e9)
- [Using Proxy Protocol With Nginx](https://chrislea.com/2014/03/20/using-proxy-protocol-nginx/)
- [Proxying WebSockets with Nginx](https://chrislea.com/2013/02/23/proxying-websockets-with-nginx/)
- [WebSockets on AWS’s ELB](http://www.raweng.com/blog/2014/11/11/websockets-on-aws-elb/)
- [Gist: haproxy.cfg Monitor & Reload](https://gist.github.com/allanparsons/6076098)
- [Configuring Websockets behind an AWS ELB](http://blog.jverkamp.com/2015/07/20/configuring-websockets-behind-an-aws-elb/)

- [Managing CoreOS Clusters on AWS with CloudFormation](http://blog.michaelhamrah.com/2015/03/managing-coreos-clusters-on-aws-with-cloudformation/)

Some example scripts that helped with this project:

- [https://github.com/rombie/contrail-kubernetes-salt/blob/master/kubernetes/cluster/aws/util.sh]()
- [https://github.com/mdlavin/inin-and-out-gameday-2014/blob/master/create.sh]()
- [https://github.com/Memba/Memba-AWS/blob/master/commands/create-ec2-vpc.sh]()
- [https://github.com/fintanr/aws-ecs-experiments/blob/master/ecs-demo-setup.sh]()
- [https://github.com/mathbruyen/home/blob/master/boot.sh]()
