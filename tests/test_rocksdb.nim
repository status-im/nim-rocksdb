import ../rocksdb, os

type
  MyDB = object
    rocksdb: RocksDBInstance

# TODO no tests for failures / error reporting

proc initMyDb(path: string): MyDB =
  let
    dataDir = path / "data"
    backupsDir = path / "backups"

  createDir(dataDir)
  createDir(backupsDir)

  var s = result.rocksdb.init(dataDir, backupsDir)
  doAssert s.ok, $s

proc main =
  var db = initMyDb("/tmp/mydb")
  defer: close(db.rocksdb)

  let key = @[byte(1), 2, 3, 4, 5]
  let otherKey = @[byte(1), 2, 3, 4, 5, 6]
  let val = @[byte(1), 2, 3, 4, 5]

  var s = db.rocksdb.put(key, val)
  doAssert s.ok, $s

  var r1 = db.rocksdb.getBytes(key)
  doAssert r1.ok and r1.value == val, $r1

  var r2 = db.rocksdb.getBytes(otherKey)
  doAssert r2.ok and r2.value.len == 0, $r2

  var e1 = db.rocksdb.contains(key)
  doAssert e1.ok and e1.value == true, $e1

  var e2 = db.rocksdb.contains(otherKey)
  doAssert e2.ok and e2.value == false, $e2

  s = db.rocksdb.del(key)
  doAssert s.ok, $s

  e1 = db.rocksdb.contains(key)
  doAssert e1.ok and e1.value == false, $e1

main()

