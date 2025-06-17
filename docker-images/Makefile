BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

.PHONY: all buildbox testboxes tag_latest_buildbox tag_latest_testboxes tag_latest upload_buildbox upload_testboxes upload pull pull_buildbox pull_testboxes

all: buildbox testboxes

testboxes: testbox-el-8 testbox-el-9 testbox-el-10

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

buildbox-labels:
	echo "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-labels:
	echo "$(TESTBOX_BASE_NAME)_rocky_8:$(TESTBOX_VERSION)"
	echo "$(TESTBOX_BASE_NAME)_rocky_9:$(TESTBOX_VERSION)"
	echo "$(TESTBOX_BASE_NAME)_rocky_10:$(TESTBOX_VERSION)"

testbox-el-%:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)" "testbox-rocky-$*"

tag_latest_buildbox:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64 $(BUILDBOX_NAME):latest-arm64
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64 $(BUILDBOX_NAME):latest-amd64

tag_latest_testbox_%:
	docker tag $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_rocky_$*:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_rocky_$*:latest-amd64

tag_latest_testboxes:
	$(MAKE) tag_latest_testbox_8
	$(MAKE) tag_latest_testbox_9
	$(MAKE) tag_latest_testbox_10

tag_latest: tag_latest_buildbox tag_latest_testboxes

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

upload_testbox_%:
	docker push $(TESTBOX_BASE_NAME)_rocky_$*:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_rocky_$*:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-amd64

upload_testboxes: tag_latest_testboxes
	$(MAKE) upload_testbox_8
	$(MAKE) upload_testbox_9
	$(MAKE) upload_testbox_10

release_testbox_%:
	docker manifest rm $(TESTBOX_BASE_NAME)_rocky_$*:latest || true
	docker manifest create $(TESTBOX_BASE_NAME)_rocky_$*:latest             $(TESTBOX_BASE_NAME)_rocky_$*:latest-amd64	     $(TESTBOX_BASE_NAME)_rocky_$*:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-arm64
	docker manifest push --purge $(TESTBOX_BASE_NAME)_rocky_$*:latest
	docker manifest push $(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)

release_testboxes: upload_testboxes
	$(MAKE) release_testbox_8
	$(MAKE) release_testbox_9
	$(MAKE) release_testbox_10

upload: upload_buildbox upload_testboxes
release: release_buildbox release_testboxes

pull: pull_buildbox pull_testboxes

pull_buildbox:
	docker pull --platform linux/arm64 "ghcr.io/$(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64"
	docker pull --platform linux/amd64 "ghcr.io/$(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64"
	docker tag "ghcr.io/$(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64" "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64"
	docker tag "ghcr.io/$(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64" "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64"

pull_testboxes:
	$(MAKE) pull_testbox_8
	$(MAKE) pull_testbox_9
	$(MAKE) pull_testbox_10

pull_testbox_%:
	docker pull --platform linux/arm64 "ghcr.io/$(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-arm64"
	docker pull --platform linux/amd64 "ghcr.io/$(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-amd64"
	docker tag "ghcr.io/$(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-arm64" "$(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-arm64"
	docker tag "ghcr.io/$(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-amd64" "$(TESTBOX_BASE_NAME)_rocky_$*:$(TESTBOX_VERSION)-amd64"
