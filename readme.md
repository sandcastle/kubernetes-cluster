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


## Further Reading
Some articles that helped with this project:

- [Kubernetes Cluster on CoreOS - v1.0](https://github.com/kubernetes/kubernetes/blob/release-1.0/docs/getting-started-guides/coreos/coreos_multinode_cluster.md)
- [CoreOS on AWS](https://coreos.com/os/docs/latest/booting-on-ec2.html)
- [VPC reference architecture](http://blog.bwhaley.com/reference-vpc-architecture)
- [Zero downtime deployments](http://waytothepiratecove.blogspot.com.au/2015/03/delivery-pipeline-and-zero-downtime.html)

Some articles yet to be read that may provide value:

- [http://marceldegraaf.net/2014/05/05/coreos-follow-up-sinatra-logstash-elasticsearch-kibana.html]()
- [http://blog.michaelhamrah.com/2015/03/managing-coreos-clusters-on-aws-with-cloudformation/]()

Some example scripts that helped with this project:

- [https://github.com/rombie/contrail-kubernetes-salt/blob/599f2ffc4f80ee280fcf382d5a651310a0de4f1d/kubernetes/cluster/aws/util.sh]()
- [https://github.com/mdlavin/inin-and-out-gameday-2014/blob/df6b4c52ebd3b9dea81abae7e626c30bcff3fbc7/create.sh]()
- [https://github.com/Memba/Memba-AWS/blob/ecccd07ed64318845edbb471a9dfd3f2faae87e1/commands/create-ec2-vpc.sh]()
- [https://github.com/fintanr/aws-ecs-experiments/blob/4bfa4bb9f3e8e497309ff6bf1ee1bbce87b5c944/ecs-demo-setup.sh]()
- [https://github.com/mathbruyen/home/blob/1b59c5302707de47c006e29e82689f04003bb05b/boot.sh]()
