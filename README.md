# zz-gijonbus-poc

script for query data from Gijón Bus dataset, normalize and inject into kafka topic

# BUILDING

- Build docker image:
  * git clone https://github.com/wjjpt/zz-gijonbus-poc.git
  * cd src/
  * docker build -t wjjpt/gijonbus2k .

# EXECUTING

- Execute app using docker image:

`docker run --env KAFKA_BROKER=X.X.X.X --env KAFKA_PORT=9092 --env KAFKA_TOPIC='gijonbus' -ti wjjpt/gijonbus2k`

