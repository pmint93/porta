# Porta

### Description

  a latency and fault tolerance API gateway based on Sinatra using DNS for services discovering

### This repo contain [AWS Cloud Formation stack template](aws-cf-stack.template)

### Running along with some components:

* [Semian](https://github.com/Shopify/semian) as a Resilient libraly

* [Consul](https://www.consul.io) as Service discovery

* [Registrator](http://gliderlabs.com/registrator/latest/) as Service registry, plugged into Consul

### Architecture
  * [Service Discovery via Consul with Amazon ECS](https://aws.amazon.com/blogs/compute/service-discovery-via-consul-with-amazon-ecs/)
