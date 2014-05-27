import kdb

ks1 = kdb.KeySet(100,
	kdb.Key("user/key1"),
	kdb.Key("user/key2"),
	kdb.Key("user/key3")
	)

print("KeySet1 has {0} keys".format(len(ks1)))
print("")

print("We can easily iterate over the keyset to check out its content:")
for k in ks1:
	print("  {0}".format(k))
print("")

print("This works the other direction too:")
for k in reversed(ks1):
	print("  {0}".format(k))
print("")

print("We can check if a key is in a keyset:")
print("  Is user/key1 in KeySet1? {0}".format("user/key1" in ks1))
print("This works with Key objects too:")
print("  Is Key(system/key1) in KeySet1? {0}".format("system/key1" in ks1))
print("")

print("Index access is supported as well:")
print("  KeySet1[1]={0}".format(ks1[1]))
print("  KeySet1[-1]={0}".format(ks1[-1]))
print("  KeySet1['user/key1']={0}".format(ks1["user/key1"]))
print("  KeySet1['doesnt_exist']={0}".format(ks1["doesnt_exist"]))
print("")

print("You asked for slices? You get slices:")
print("  KeySet1[1:3]={0}".format([ str(k) for k in ks1[1:3] ]))
print("")
