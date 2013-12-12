NAME = phusion/passenger_rpm_automation

.PHONY: all image publish_image

all:
	@echo "*** Please explicitly specify a target."
	@false

image:
	docker build -t $(NAME) -rm image

publish_image:
	docker push $(NAME)
