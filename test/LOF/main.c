
long long A[32];

int main(int argc, char *argv[]) {
#pragma clang loop vectorize(assume_safety)
	for (long long j = 0ll; j < 32ll; j += 1ll)
		   A[j] = j;
	return 0;
}
