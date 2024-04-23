PROTO_DIR = 'proto'
PROTO_SOURCES := $(shell find $(PROTO_DIR) -name '*.proto')

proto: build/gen $(PROTO_SOURCES)
	protoc --proto_path=$(PROTO_DIR) --python_out=build/gen $(PROTO_SOURCES) --mypy_out=build/gen

build/gen:
	mkdir -p $@

clean:
	rm -rf build/gen
