OW_USER?=whisk
OW_RUNTIME?=$(OW_USER)/action-swift-v4.2
OW_COMPILER?=$(OW_USER)/action-swift-v4.2
WSK?=wsk -i
MAIN=main
PACKAGE=test
SRCS=HelloSwift4/Sources/$(MAIN).swift HelloSwift4/Package.swift
NAME=swift-$(MAIN)-zip
BINZIP=$(MAIN)-bin.zip
SRCZIP=$(MAIN)-src.zip

deploy: package.done $(BINZIP)
	$(WSK) action update $(PACKAGE)/$(NAME) $(BINZIP) --main $(MAIN) --docker $(OW_RUNTIME)

devel: package.done $(SRCZIP)
	$(WSK) action update $(PACKAGE)/$(NAME) $(SRCZIP) --main $(MAIN) --docker $(OW_COMPILER)

$(BINZIP): $(SRCS)
	cd HelloSwift4 ; zip - -r * | docker run -i $(OW_COMPILER) -compile $(MAIN) >../$(BINZIP)

$(SRCZIP): $(SRCS)
	cd HelloSwift4 ; zip ../$(SRCZIP) -r *

clean:
	-$(WSK) action delete $(PACKAGE)/$(NAME)
	-rm  $(BINZIP) $(SRCZIP) package.done test.json

test: test.json
	$(WSK) action invoke test/$(NAME) -r
	$(WSK) action invoke test/$(NAME) -P test.json -r

test.json:
	echo '{ "name": "Mike" }' >test.json

package.done:
	$(WSK) package update $(PACKAGE)
	touch package.done

.PHONY: deploy devel test clean