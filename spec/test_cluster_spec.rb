require "kafka_spec_helper"
require "securerandom"

describe "Test cluster" do
  it "spins up properly" do
    producer = Poseidon::Producer.new(["localhost:9092"], "test_cluster_producer")

    random = SecureRandom.hex(4)

    producer.send_messages([
      Poseidon::MessageToSend.new("test_cluster", "hello world #{random}")
    ])

    consumer = Poseidon::PartitionConsumer.new("test_cluster_consumer", "localhost", 9092, "test_cluster", 0, :earliest_offset)

    messages = consumer.fetch

    expect(messages[0].value).to eq("hello world #{random}")
  end
end
