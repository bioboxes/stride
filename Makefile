env    = PATH=./env/bin:${PATH}
image  = biobox_testing/image

ssh: .image env
	docker run  \
		--volume=$(abspath ./biobox_verify/input):/bbx/input:ro \
		--volume=$(abspath ./biobox_verify/output):/bbx/output:rw \
		-it \
		--entrypoint=/bin/bash \
		$(image)

test: .image env
	$(env) biobox verify short_read_assembler $(image) --verbose

build: .image

.image: $(shell find image -type f) Dockerfile
	@docker build --tag $(image) .
	@touch $@

env:
	@virtualenv -p python3 $@
	@$@/bin/pip install biobox_cli
