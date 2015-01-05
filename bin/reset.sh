cd ..
bundle exec sequel -m db/migrations/ -M 0 postgres://localhost/droppings
bundle exec sequel -m db/migrations/ postgres://localhost/droppings
curl -XDELETE localhost:9200/s2p
cd bin
