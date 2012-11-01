#include "snappy.h"
#include "snappy-c.h"

int main(int argc, char *argv[])
{
 if (argc != 3)
	exit(1);

  size_t input_length;
  char*  input;

  size_t output_length;
  char*  output;

  FILE *f = fopen(argv[1], "r");
  if(f == NULL) {
    perror("Can't open test.txt");
    return 1;
  }

  /* Calculate the input length */
  fseek(f, 0L, SEEK_END);
  input_length = ftell(f);
  fseek(f, 0L, SEEK_SET);

  input = (char*)malloc(input_length);

  fread(input, input_length, 1, f);
  fclose(f);

  output_length = snappy_max_compressed_length(input_length);
  output = (char*)malloc(output_length);

  if (snappy_compress(input, input_length, output, &output_length) == SNAPPY_OK ) {
      printf("Compressed\n");
  } else {
      perror("Problem compressing the file\n");
      free(output);
      free(input);
      return 1;
  }

  /* Save the compressed file to a new location */
  f = fopen(argv[2], "w");
  fwrite(output,output_length,1,f);
  fclose(f);
}