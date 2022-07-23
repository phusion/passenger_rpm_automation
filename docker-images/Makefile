BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

.PHONY: all buildbox testboxes testbox-el-7 testbox-el-8 testbox-el-9 tag_latest_buildbox tag_latest_testbox tag_latest upload_buildbox upload_testbox upload

all: buildbox testboxes

testboxes: testbox-el-7 testbox-el-8 testbox-el-9

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

buildbox-labels:
	echo "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-labels:
	echo "$(TESTBOX_BASE_NAME)_centos_7:$(TESTBOX_VERSION)"
	echo "$(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)"
	echo "$(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)"

testbox-el-7:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_centos_7:$(TESTBOX_VERSION)" "testbox-centos-7"

testbox-el-8:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)" "testbox-rocky-8"

testbox-el-9:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)" "testbox-rocky-9"

tag_latest_buildbox:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION) $(BUILDBOX_NAME):latest

tag_latest_testbox:
	docker tag $(TESTBOX_BASE_NAME)_centos_7:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_centos_7:latest
	docker tag $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_rocky_8:latest
	docker tag $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_rocky_9:latest

tag_latest: tag_latest_testbox tag_latest_buildbox

upload_buildbox: tag_latest_buildbox
	docker push $(BUILDBOX_NAME):latest
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)

upload_testbox: tag_latest_testbox
	docker push $(TESTBOX_BASE_NAME)_centos_7:latest
	docker push $(TESTBOX_BASE_NAME)_centos_7:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_rocky_8:latest
	docker push $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_rocky_9:latest
	docker push $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)

upload: upload_testbox upload_buildbox
