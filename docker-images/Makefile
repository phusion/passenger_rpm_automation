BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

.PHONY: all buildbox testboxes testbox-el-8 testbox-el-9 tag_latest_buildbox tag_latest_testbox tag_latest upload_buildbox upload_testbox upload

all: buildbox testboxes

testboxes: testbox-el-8 testbox-el-9

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

buildbox-labels:
	echo "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-labels:
	echo "$(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)"
	echo "$(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)"

testbox-el-8:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)" "testbox-rocky-8"

testbox-el-9:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)" "testbox-rocky-9"

tag_latest_buildbox:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64 $(BUILDBOX_NAME):latest-arm64
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64 $(BUILDBOX_NAME):latest-amd64

tag_latest_testbox:
	docker tag $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_rocky_8:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_rocky_8:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_rocky_9:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_rocky_9:latest-amd64

tag_latest: tag_latest_testbox tag_latest_buildbox

upload_buildbox: tag_latest_buildbox
	docker push $(BUILDBOX_NAME):latest-arm64
	docker push $(BUILDBOX_NAME):latest-amd64
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64

release_buildbox: upload_buildbox
	docker manifest rm  $(BUILDBOX_NAME):latest || true
	docker manifest create $(BUILDBOX_NAME):$(BUILDBOX_VERSION) $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64 $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64
	docker manifest create $(BUILDBOX_NAME):latest              $(BUILDBOX_NAME):latest-amd64              $(BUILDBOX_NAME):latest-arm64
	docker manifest push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)
	docker manifest push --purge $(BUILDBOX_NAME):latest

upload_testbox: tag_latest_testbox
	docker push $(TESTBOX_BASE_NAME)_rocky_8:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_rocky_8:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_rocky_9:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_rocky_9:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)-amd64

release_testboxes: upload_testbox
	docker manifest rm $(TESTBOX_BASE_NAME)_rocky_8:latest || true
	docker manifest create $(TESTBOX_BASE_NAME)_rocky_8:latest             $(TESTBOX_BASE_NAME)_rocky_8:latest-amd64	     $(TESTBOX_BASE_NAME)_rocky_8:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)-arm64
	docker manifest push --purge $(TESTBOX_BASE_NAME)_rocky_8:latest
	docker manifest push $(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)
	docker manifest rm $(TESTBOX_BASE_NAME)_rocky_9:latest || true
	docker manifest create $(TESTBOX_BASE_NAME)_rocky_9:latest             $(TESTBOX_BASE_NAME)_rocky_9:latest-amd64	     $(TESTBOX_BASE_NAME)_rocky_9:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)-arm64
	docker manifest push --purge $(TESTBOX_BASE_NAME)_rocky_9:latest
	docker manifest push $(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)

upload: upload_testbox upload_buildbox
release: release_buildbox release_testboxes
