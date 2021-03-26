BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

.PHONY: all buildbox testboxes testbox-centos-7 testbox-centos-8 upload

all: buildbox testboxes

testboxes: testbox-centos-7 testbox-centos-8

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-centos-7:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_centos_7:$(TESTBOX_VERSION)" "testbox-centos-7"

testbox-centos-8:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_centos_8:$(TESTBOX_VERSION)" "testbox-centos-8"

tag_latest:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION) $(BUILDBOX_NAME):latest
	docker tag $(TESTBOX_BASE_NAME)_centos_7:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_centos_7:latest
	docker tag $(TESTBOX_BASE_NAME)_centos_8:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_centos_8:latest

upload: tag_latest
	docker push $(BUILDBOX_NAME):latest
	docker push $(BUILDBOX_NAME):$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_centos_7:latest
	docker push $(TESTBOX_BASE_NAME)_centos_7:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_centos_8:latest
	docker push $(TESTBOX_BASE_NAME)_centos_8:$(TESTBOX_VERSION)
