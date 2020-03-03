ifeq ('$(OS)', 'Windows_NT')
PWSH=powershell -noprofile -command
endif

IMAGE_ORG=tmcphillips
IMAGE_NAME=p418-notebooks-r
IMAGE_TAG=latest
TAGGED_IMAGE=${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_TAG}

REPRO_DIR=/mnt/p418NotebooksR
RUN_REPRO=docker run -it --rm -p 8787:8787           \
                     --volume $(CURDIR):$(REPRO_DIR)  \
                     $(TAGGED_IMAGE)

ifdef IN_RUNNING_REPRO
RUN_IN_REPRO=bash -ic
else
RUN_IN_REPRO=$(RUN_REPRO) bash -ic
endif

## 
## ------------------------------------------------------------------------------
##        Make targets available both INSIDE and OUTSIDE a running REPRO
## 

help:                   ## Show this help.
ifdef PWSH
	@${PWSH} "Select-String -Path $(MAKEFILE_LIST) -Pattern '#\# ' | % {$$_.Line.replace('##','')}"
else
	@sed -ne '/@sed/!s/#\# //p' $(MAKEFILE_LIST)
endif

run:                    ## Run notebooks and render R Markdown.
	$(RUN_IN_REPRO) 'make -C $(REPRO_DIR)/notebooks run'

clean:                  ## Delete all products of the notebooks.
	$(RUN_IN_REPRO) 'make -C $(REPRO_DIR)/notebooks clean'

rstudio:                ## Start RStudio Server and load the All_Harvest project.
ifdef IN_RUNNING_REPRO
	@sudo rstudio-server start
	@echo "\n--------------------------------------------------------------------------"
	@echo   "The RStudio Server is now running.  Connect to it by navigating in your"
	@echo   "web browser to http://localhost:8787 (Username: repro, Password: repro)"
	@echo
	@echo   "Exit from this terminal session to shut down RStudio Server."
	@echo   "--------------------------------------------------------------------------\n"
else
	@$(RUN_IN_REPRO) 'make rstudio; bash -il'
endif

## ------------------------------------------------------------------------------
##            Make targets available only OUTSIDE a running REPRO
## 


ifndef IN_RUNNING_REPRO

start:                  ## Start a bash session in a new Docker container.
	$(RUN_REPRO)

image:                  ## Build the Docker image used to run this REPRO.
	docker build -t ${TAGGED_IMAGE} .

pull-image:             ## Pull the Docker image from Docker Hub.
	docker pull ${TAGGED_IMAGE}

push-image:             ## Push the Docker image to Docker Hub.
	docker push ${TAGGED_IMAGE}

## 

stop-all-containers:    ## Gently stop all running Docker containers.
ifdef PWSH
	${PWSH} 'docker ps -q | % { docker stop $$_ }'
else
	for c in $$(docker ps -q); do docker stop $$c; done
endif

kill-all-containers:    ## Forcibly stop all running Docker containers.
ifdef PWSH
	${PWSH} 'docker ps -q | % { docker kill $$_ }'
else
	for c in $$(docker ps -q); do docker kill $$c; done
endif

remove-all-containers:  ## Delete all stopped Docker containers.
ifdef PWSH
	${PWSH} 'docker ps -aq | % { docker rm $$_ }'
else
	for c in $$(docker ps -aq); do docker rm $$c; done
endif

remove-all-images:      ## Delete all Docker images on this computer.
ifdef PWSH
	${PWSH} 'docker images -aq | % { docker rmi $$_ }'
else
	for i in $$(docker images -aq); do docker rmi $$i; done
endif

purge-docker:           ## Purge all Docker containers and images from computer.
purge-docker: stop-all-containers kill-all-containers remove-all-containers remove-all-images

endif

## ------------------------------------------------------------------------------
## 
