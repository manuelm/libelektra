%module kdb

%include "attribute.i"
%include "std_string.i"
%include "stl.i"
%include "exception.i"

%{
  extern "C" {
    #include "kdbconfig.h"
    #include "kdb.h"
  }

  #include "keyexcept.hpp"
  #include "kdbexcept.hpp"
  #include "key.hpp"
  #include "keyset.hpp"
  #include "kdb.hpp"
  using namespace kdb;
%}

%apply long { ssize_t }

/*
 * kdbconfig.h
 */
%constant const char *DB_SYSTEM = KDB_DB_SYSTEM;
%constant const char *DB_USER = KDB_DB_USER;
%constant const char *DB_HOME = KDB_DB_HOME;
%constant bool DEBUG = DEBUG;
%constant bool VERBOSE = VERBOSE;


/*
 * kdb.h
 */
%constant void *KS_END = KS_END;
%constant const char *VERSION = KDB_VERSION;
%constant const short VERSION_MAJOR = KDB_VERSION_MAJOR;
%constant const short VERSION_MINOR = KDB_VERSION_MINOR;
%constant const short VERSION_MICRO = KDB_VERSION_MICRO;
// we only care about the enums. ignore the c functions
%ignore ckdb;
%include "kdb.h"


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

  #define KEY_EXCEPTIONS \
    KDB_CATCH_EX(kdb, KeyTypeMismatch) \
    KDB_CATCH_EX(kdb, KeyInvalidName) \
    KDB_CATCH_EX(kdb, KeyBadMeta) \
    KDB_CATCH_EX(kdb, KeyMetaException) \
    KDB_CATCH_EX(kdb, KeyException) \
    KDB_CATCH_EX(kdb, Exception)

  #define KDB_EXCEPTIONS \
    KDB_CATCH_EX(kdb, KDBException) \
    KDB_CATCH_EX(kdb, Exception)
%}

#define KDB_CATCH(exceptions) \
  try { \
    $action \
  } \
  exceptions \
  catch (const std::exception & e) { \
    SWIG_exception(SWIG_RuntimeError, e.what()); \
  } \
  catch (...) { \
    SWIG_exception(SWIG_UnknownError, "unknown error in $decl"); \
  }

%exceptionclass kdb::Exception;
%extend kdb::Exception {
  %pythoncode {
    def __str__(self):
      return self.what()
  }
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

// operator overloading sucks
%ignore kdb::Key::operator->;
%ignore kdb::Key::operator=;
%ignore kdb::Key::operator+=;
%ignore kdb::Key::operator-=;

// constructors
%ignore kdb::Key::Key (Key const &k);
%ignore kdb::Key::Key (const char *keyName, ...);
%ignore kdb::Key::Key (const std::string keyName, ...);
%ignore kdb::Key::Key (const char *keyName, va_list ap);

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
      self.setMeta("mode", "{0:o}".format(next(args)))
    elif arg == KEY_ATIME:
      self.setMeta("atime", "{0:d}".format(next(args)))
    elif arg == KEY_MTIME:
      self.setMeta("mtime", "{0:d}".format(next(args)))
    elif arg == KEY_CTIME:
      self.setMeta("ctime", "{0:d}".format(next(args)))
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

// reference handling
%ignore kdb::Key::operator++(int) const;
%ignore kdb::Key::operator--(int) const;
%rename(_incRef) kdb::Key::operator++;
%rename(_decRef) kdb::Key::operator--;

// reference counted object
//%feature("ref")   kdb::Key "$this->operator++();"
//%feature("unref") kdb::Key "$this->operator--();"

// name manipulation
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

%rename("_%s") kdb::Key::getNameSize;
%rename("_%s") kdb::Key::getBaseNameSize;
%rename("_%s") kdb::Key::getFullNameSize;

// value operations
%rename("_%s") kdb::Key::getString;
%rename("_%s") kdb::Key::setString;
%rename("_%s") kdb::Key::getStringSize;
%rename("_%s") kdb::Key::getFunc;

%rename("_%s") kdb::Key::getBinary;
%rename("_%s") kdb::Key::setBinary;
%rename("_%s") kdb::Key::getBinarySize;
%rename("_%s") kdb::Key::getValue;

%rename("_%s") kdb::Key::rewindMeta;
%rename("_%s") kdb::Key::nextMeta;
%rename("_%s") kdb::Key::currentMeta;

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

  %pythoncode {
    def get(self):
      if self.isBinary():
        return self._getBinary()
      return self._getString()

    def set(self, value):
      if isinstance(value, bytes):
        return self._setBinary(value)
      return self._setString(str(value))

    def getMeta(self, *args):
      if len(args):
        return self._getMeta(*args)
      return self.__metaIter()

    def setMeta(self, name, value):
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
  }
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
%apply ssize_t { cursor_t }

%ignore kdb::KeySet::KeySet(size_t alloc, va_list ap);
%ignore kdb::KeySet::KeySet(size_t alloc, ...);
%ignore kdb::KeySet::operator=;

%pythonprepend kdb::KeySet::KeySet {
  orig = []
  if len(args):
    orig = args[1:]
    args = [ args[0] ]
}

%pythonappend kdb::KeySet::KeySet {
  for arg in orig:
    # check for KS_END
    if arg is None:
      break
    self.append(arg)
}

%rename(__len__) kdb::KeySet::size;

%ignore kdb::KeySet::rewind;
%ignore kdb::KeySet::next;
%ignore kdb::KeySet::current;

%rename("_%s") kdb::KeySet::lookup;

%extend kdb::KeySet {
  KeySet(size_t alloc) {
   return new kdb::KeySet(alloc, KS_END);
  }

  %pythoncode {
    def lookup(self, *args):
      key = self._lookup(*args)
      return key if key else None

    def __getitem__(self, key):
      if isinstance(key, slice):
        return [ self[k] for k in range(*key.indices(len(self))) ]
      elif isinstance(key, ( int, str, Key )):
        return self.lookup(key)
      raise TypeError("Invalid argument type")

    def __contains__(self, item):
      if isinstance(item, ( str, Key )):
        key = self._lookup(item)
        return True if key else False
      raise TypeError("Invalid argument type")
  }
}

// iterators
// we hide all iterator classes. users should use python iter/reversed
#define WITHOUT_KEYSET_ITERATOR

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

%include "kdb.hpp"

// clear exception handler
%exception;
