run_luacheck:
	luacheck lua/snippet_converter

run_tests:
	vusted tests --output=gtest

gen_tag:
	./scripts/generate_tag.sh
