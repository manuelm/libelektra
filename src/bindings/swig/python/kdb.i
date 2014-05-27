%module kdb

%include "stl.i"
%include "../common.i"
%feature("autodoc", "3");


/* handle exceptions */
%{
  #define KDB_CATCH_EX(namespace, exception) \
    catch(const namespace::exception &e) \
    { \
      SWIG_Python_Raise(SWIG_NewPointerObj(new namespace::exception(e), \
        SWIGTYPE_p_##namespace##__##exception, SWIG_POINTER_OWN), \
        #exception, SWIGTYPE_p_##namespace##__##exception); \
      SWIG_fail; \
    }
%}

%exceptionclass kdb::Exception;
%extend kdb::Exception {
  %pythoncode %{
    def __str__(self):
      return self.what()
  %}
}
%include "keyexcept.hpp"
%include "kdbexcept.hpp"


/*
 * key.hpp
 */
// exception handling for kdb::Key
%exception {
  KDB_CATCH(KEY_EXCEPTIONS)
}

// constructors
%pythonprepend kdb::Key::Key {
  orig = []
  if len(args):
    orig = args[1:]
    args = [ args[0] ]
}

%pythonappend kdb::Key::Key {
  args = iter(orig)
  for arg in args:
    if arg == KEY_END:
      break
    elif arg == KEY_NAME:
      self.name = next(args)
    elif arg == KEY_VALUE:
      self.value = next(args)
    elif arg == KEY_OWNER:
      self.setMeta("owner", next(args))
    elif arg == KEY_COMMENT:
      self.setMeta("comment", next(args))
    elif arg == KEY_BINARY:
      pass
    elif arg == KEY_UID:
      self.setMeta("uid", str(next(args)))
    elif arg == KEY_GID:
      self.setMeta("gid", str(next(args)))
    elif arg == KEY_MODE:
      self.setMeta("mode", "{0:o}".format(int(next(args))))
    elif arg == KEY_ATIME:
      self.setMeta("atime", "{0:d}".format(int(next(args))))
    elif arg == KEY_MTIME:
      self.setMeta("mtime", "{0:d}".format(int(next(args))))
    elif arg == KEY_CTIME:
      self.setMeta("ctime", "{0:d}".format(int(next(args))))
    elif arg == KEY_SIZE:
      pass
    elif arg == KEY_FUNC:
      #TODO swig directors?
      raise TypeError("Unsupported meta type")
    elif arg == KEY_DIR:
      meta = self.getMeta("mode")
      mode = int(meta.value, 8) if meta else 0
      self.setMeta("mode", "{0:o}".format(mode | 0o111))
    elif arg == KEY_META:
      self.setMeta(next(args), next(args))
    elif arg == KEY_NULL:
      pass
    else:
      if DEBUG:
        import sys
        print("Unknown option in keyNew {0}".format(arg), file=sys.stderr)
}

// properties
// we can't use %attribute here swig won't generate exception code for
// properties. thus we rename and create them using pure python code below
//%attributestring(kdb::Key, std::string, name,     getName, setName);
//%attributestring(kdb::Key, std::string, basename, getBaseName, setBaseName);
//%attributestring(kdb::Key, std::string, dirname,  getDirName);
//%attributestring(kdb::Key, std::string, fullname, getFullName);
%rename("_%s") kdb::Key::getName;
%rename("_%s") kdb::Key::setName;
%rename("_%s") kdb::Key::getBaseName;
%rename("_%s") kdb::Key::setBaseName;
%rename("_%s") kdb::Key::getDirName;
%rename("_%s") kdb::Key::getFullName;

// only accept binary data in binary functions
%typemap(out) std::string kdb::Key::getBinary {
  $result = PyBytes_FromStringAndSize($1.data(), $1.size());
}

%typemap(in) (const void *newBinary, size_t dataSize) {
  Py_ssize_t len;
  if(PyBytes_AsStringAndSize($input, reinterpret_cast<char **>(&$1), &len) == -1)
    return NULL;
  $2 = len;
}

%typemap(out) void *kdb::Key::getValue {
  ssize_t size = arg1->getBinarySize();
  $result = PyBytes_FromStringAndSize((const char*)$1, (size > 0) ? size : 0);
}

// add some other useful methods
%extend kdb::Key {
  Key(const char *keyName) {
    return new kdb::Key(keyName, KEY_END);
  }

  int __cmp__(const Key *o) {
    return ckdb::keyCmp($self->getKey(), o->getKey());
  }

  %pythoncode %{
    def get(self):
      """returns the keys value"""
      if self.isBinary():
        return self._getBinary()
      return self._getString()

    def set(self, value):
      """set the keys value. Can be either string or binary"""
      if isinstance(value, bytes):
        return self._setBinary(value)
      return self._setString(str(value))

    def getMeta(self, name = None):
      """returns a meta key given by name. Name can be either string or Key.
      If no meta key is found None is returned.
      If name is omitted an iterator object is returned.
      """
      if name is not None:
        meta = self._getMeta(name)
        return meta if meta else None
      return self.__metaIter()

    def setMeta(self, name, value):
      """set a new meta key consisting of name and value"""
      if isinstance(value, str):
        return self._setMeta(name, value)
      raise TypeError("Unsupported value type")

    def __metaIter(self):
      self._rewindMeta()
      meta = self._nextMeta()
      while meta:
        yield meta
        meta = self._nextMeta()

    name     = property(_kdb.Key__getName, _kdb.Key__setName)
    value    = property(get, set, None, "Key value")
    basename = property(_kdb.Key__getBaseName, _kdb.Key__setBaseName)
    dirname  = property(_kdb.Key__getDirName)
    fullname = property(_kdb.Key__getFullName)

    def __str__(self):
      return self.name
  %}
};

%include "key.hpp"

// meta data
%template(_getMeta) kdb::Key::getMeta<const kdb::Key>;
%template(_setMeta) kdb::Key::setMeta<std::string>;

// clear exception handler
%exception;


/*
 * keyset.hpp
 */
%pythonprepend kdb::KeySet::KeySet %{
  orig = []
  if len(args):
    orig = args[1:]
    args = [ args[0] ]
%}

%pythonappend kdb::KeySet::KeySet %{
  for arg in orig:
    if arg is KS_END:
      break
    self.append(arg)
%}

%rename(__len__) kdb::KeySet::size;

%ignore kdb::KeySet::rewind;
%ignore kdb::KeySet::next;
%ignore kdb::KeySet::current;

%rename("_%s") kdb::KeySet::lookup;
%rename("_lookup") kdb::KeySet::at;

%extend kdb::KeySet {
  KeySet(size_t alloc) {
   return new kdb::KeySet(alloc, KS_END);
  }

  %pythoncode %{
    def lookup(self, name):
      """Lookup a key by name. Name can be either string, Key or indexes.
      If index is negative, search starts at the end.
      Returns None if no key is found.
      """
      key = self._lookup(name)
      return key if key else None

    def __getitem__(self, key):
      """See lookup(...) for details.
      Slices and negative indexes are supported as well.
      """
      if isinstance(key, slice):
        return [ self[k] for k in range(*key.indices(len(self))) ]
      elif isinstance(key, ( int, str, Key )):
        return self.lookup(key)
      raise TypeError("Invalid argument type")

    def __contains__(self, item):
      """See lookup(...) for details"""
      if isinstance(item, ( str, Key )):
        key = self._lookup(item)
        return True if key else False
      raise TypeError("Invalid argument type")
  %}
}

// define traits needed by SwigPyIterator
%fragment("SwigPyIterator_T");
%traits_swigtype(kdb::Key);
%fragment(SWIG_Traits_frag(kdb::Key));
%extend kdb::KeySet {
  swig::SwigPyIterator* __iter__(PyObject **PYTHON_SELF) {
    return swig::make_output_iterator(self->begin(), self->begin(),
      self->end(), *PYTHON_SELF);
  }

  swig::SwigPyIterator* __reversed__(PyObject **PYTHON_SELF) {
    return swig::make_output_iterator(self->rbegin(), self->rbegin(),
      self->rend(), *PYTHON_SELF);
  }
}

%include "keyset.hpp"


/*
 * kdb.hpp
 */
// exception handling for kdb::KDB
%exception {
  KDB_CATCH(KDB_EXCEPTIONS)
}

%extend kdb::KDB {
  %pythoncode %{
    def __enter__(self):
      """Internal method for usage with context managers"""
      return self

    def __exit__(self, type, value, tb):
      """Internal method for usage with context managers.
      Closes the database.
      """
      try:
        self.close(Key())
      except:
        pass
  %}
}

%include "kdb.hpp"

// clear exception handler
%exception;
