migrations:
	kong migrations up

wait-for-it:
	/wait-for-it.sh db:5432 -t 300

jenkins: wait-for-it migrations
	bin/busted -o gtest spec/copy-header
