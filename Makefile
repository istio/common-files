# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

update-protos:
	@./get_protos.sh

lint:
	@cp files/common/Makefile.common.mk files/Makefile.core.mk
	@echo >files/Makefile.overrides.mk "BUILD_WITH_CONTAINER ?= 1"
	@cd files && make -f Makefile lint-all
	@rm files/Makefile.core.mk files/Makefile.overrides.mk

update-build-image:
	@bin/update_build_image.sh
