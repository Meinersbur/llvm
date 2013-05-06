 
#ifndef LLVM_ADT_STACKVECTOR_H
#define LLVM_ADT_STACKVECTOR_H

namespace llvm {

#define LLVM_STACKVECTOR(NAME, T, n) \
	size_t CONCAT(NAME,_capacity) = (n);  \
	char CONCAT(NAME,_storage)[CONCAT(NAME,_capacity) * sizeof(T)]; \
	StackVector<T> (NAME)(&CONCAT(NAME,_storage), CONCAT(NAME,_capacity));



template <typename T, typename = void>
class StackVectorTemplateCommon {
protected:
	 T * const Storage;
	 const size_t Capacity;
	 size_t Count;

protected:
	 StackVectorTemplateCommon( T * const Storage, const size_t Capacity) Storage(Storage), Capacity(Capacity), Count(0) {
	 }

public:
};


template<typename T, bool isPodType>
class StackVectorTemplateBase;

template<typename T>
class StackVectorTemplateBase<T, true> : public StackVectorTemplateCommon<T> {

};

template<typename T>
class StackVectorTemplateBase<T, false> : public StackVectorTemplateCommon<T> {

};


template<typename T>
class StackVector {
private:
	StackVector(const StackVector&) LLVM_DELETED_FUNCTION;

public:
  typedef typename SuperClass::iterator iterator;
  typedef typename SuperClass::size_type size_type;

private:

public:
	 ~StackVector() {
	 	}

	 StackVector() : Storage(NULL), Capacity(capacity), Count(0) {
	 }

	StackVector(T * const storage, size_t capacity) : Storage(storage), Capacity(capacity), Count(0) {
	}

private:

	  /// grow_pod - This is an implementation of the grow() method which only works
	  /// on POD-like data types and is out of line to reduce code duplication.
	  void grow_pod(void *FirstEl, size_t MinSizeInBytes, size_t TSize);

	public:
	  /// size_in_bytes - This returns size()*sizeof(T).
	  size_t size_in_bytes() const {
	    return size_t((char*)EndX - (char*)BeginX);
	  }

	  /// capacity_in_bytes - This returns capacity()*sizeof(T).
	  size_t capacity_in_bytes() const {
	    return size_t((char*)CapacityX - (char*)BeginX);
	  }

	  bool empty() const { return BeginX == EndX; }

};


} // namepspace llvm

#endif /* LLVM_ADT_STACKVECTOR_H */
