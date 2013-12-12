NAME = phusion/passenger_rpm_automation

.PHONY: all container publish_container

all:
	@echo "*** Please explicitly specify a target."
	@false

container:
	docker build -t $(NAME) -rm image

publish_container:
	docker push $(NAME)
