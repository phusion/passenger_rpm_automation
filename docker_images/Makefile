.PHONY: all buildbox testboxes testbox-centos-6 testbox-centos-7 upload

all: buildbox testboxes

testboxes: testbox-centos-6 testbox-centos-7

buildbox:
	./setup-buildbox-docker-image

testbox-centos-6:
	./setup-testbox-docker-image-centos-6

testbox-centos-7:
	./setup-testbox-docker-image-centos-7

upload:
	docker push phusion/passenger_rpm_automation_buildbox
	docker push phusion/passenger_rpm_automation_testbox_centos6
	docker push phusion/passenger_rpm_automation_testbox_centos7
