# Тестируем как можно больше кейсов.
defmodule ExampleTest do
    use ExUnit.Case
    doctest Storage

    setup_all do
        {:ok, recipient: "ok"}
    end

    test "test1" do
        assert Storage.create("key1", "value1", 100) == "ok"
        assert Storage.read("key1") == [{:kv, "key1", "value1", 100}]
        assert Storage.update("key1", "val1", 100) == "ok"
        assert Storage.read("key1") == [{:kv, "key1", "val1", 100}]
        assert Storage.delete("key1") == "ok"
        assert Storage.read("key1") == []
    end
    test "test2" do
        assert Storage.create("key2", "value2", 100) == "ok"
        assert Storage.read("key2") == [{:kv, "key2", "value2", 100}]
        assert Storage.update("key2", "val2", -1000) == "error"
        assert Storage.read("key2") == [{:kv, "key2", "value2", 100}]
        assert Storage.delete("key2") == "ok"
        assert Storage.read("key2") == []
    end
    test "test3" do
        assert Storage.create("key3", "value3", "100") == "error"
        assert Storage.read("key3") == []
    end
    test "test4" do
        assert Storage.create("key4", "value4", 100) == "ok"
        assert Storage.read("key4") == [{:kv, "key4", "value4", 100}]
        assert :lists.member(["key4", "value4", 100],  Storage.get_table()) == true
        assert Storage.delete("key4") == "ok"
        assert Storage.read("key4") == []
        assert :lists.member(["key4", "value4", 100],  Storage.get_table()) == false
    end
    test "test5" do
        assert Storage.create("key5", "value5", 100) == "ok"
        assert Storage.read("key5") == [{:kv, "key5", "value5", 100}]
        assert :lists.member(["key5", "value5", 100],  Storage.get_table()) == true
        assert Storage.update("key5", "val5", 200) == "ok"
        assert Storage.read("key5") == [{:kv, "key5", "val5", 200}]
        assert :lists.member(["key5", "value5", 100],  Storage.get_table()) == false
        assert :lists.member(["key5", "val5", 200],  Storage.get_table()) == true
        assert Storage.delete("key5") == "ok"
        assert Storage.read("key5") == []
        assert :lists.member(["key5", "value5", 200],  Storage.get_table()) == false
    end
end