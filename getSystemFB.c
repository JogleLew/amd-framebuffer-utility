#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>

char partitionName[1024], otoolPath[1024];
char value[][9] = {
"02000000", "04000000", "80000000", "10000000",
"00020000", "00040000", "00080000"};

char type[][7] = {"LVDS", "DDVI", "SVIDEO", "VGA", "SDVI", "DP", "HDMI"};

int hasPrefix(char* src, char *prefix);
int hexdec(char* addr);
void handleBlank(char* dst, char* src);
void findProperKext();
void runOtool(char* kextName);
void processData(FILE* otoolResult, FILE* kextFile);

int main(int argc, char const *argv[])
{
	// Argument[1] -> Partition Name
	// Argument[2] -> `otool` Path
	strcpy(partitionName, argv[1]);
	strcpy(otoolPath, argv[2]);
	if (argc != 3 || strlen(partitionName) > 100 || strlen(otoolPath) > 254) {
		return -1;
	}
	
	findProperKext();
	return 0;
}

int hasPrefix(char* src, char *prefix) {
	// return 1 if src has prefix, return 0 otherwise.

	int i, flag = 1;
	if (strlen(src) < strlen(prefix))
		return 0;
	for (i = 0; i < strlen(prefix); i++)
		if (src[i] != prefix[i]) {
			flag = 0; break;
		}
	return flag;
}

int hexdec(char* addr) {
	int i, result = 0;
	for (i = 0; i < strlen(addr); i++) {
		if (addr[i] >= '0' && addr[i] <= '9')
			result = 16 * result + addr[i] - '0';
		else {
			result = 16 * result + addr[i] - 'a' + 10;
		}
	}
	return result;
}

void handleBlank(char* dst, char* src) {
	int i, j = 0;
	for (i = 0; i < strlen(src); i++)
		if (src[i] != ' ')
			dst[j++] = src[i];
		else {
			dst[j++] = '\\';
			dst[j++] = ' ';
		}
	dst[j] = '\0';
}

void findProperKext() {
	int i, flag;
	char path[1024], kextName[255], ATIAMD[4], controller[11] = "Controller";
	DIR *dir;
	struct dirent *ptr;

	// check AMD(10.10+) or ATI(10.9)
	sprintf(path, "/Volumes/%s/System/Library/Extensions/AMD6000Controller.kext", partitionName);
	(access(path, 0) == 0) ? strcpy(ATIAMD, "AMD") : strcpy(ATIAMD, "ATI");
	
	// get all AMD*Controller / ATI*Controller
	sprintf(path, "/Volumes/%s/System/Library/Extensions/", partitionName);
	dir=opendir(path);
	while((ptr = readdir(dir)) != NULL) {
		if (strlen(ptr->d_name) < 22) continue;
		if (!hasPrefix(ptr->d_name, ATIAMD)) continue; // has prefix "AMD" / "ATI"

		flag = 0;
		for (i = 0; i < 10; i++) { // has suffix "Controller.kext"
			if (ptr->d_name[7 + i] != controller[i]) {
				flag = 1; break;
			}
		}
		if (flag) continue;
		printf("-------------------------%s-------------------------\n\n", ptr->d_name);
		strncpy(kextName, ptr->d_name, strlen(ptr->d_name) - 5);
		kextName[strlen(ptr->d_name) - 5] = '\0';
		runOtool(kextName);
	}
}

void runOtool(char* kextName) {
	int pid, status;
	char t1[1024], t2[1024], instruction[1024], path[1024];
	FILE* otoolResult, *kextFile;

	handleBlank(t1, otoolPath);
	handleBlank(t2, partitionName);
	sprintf(instruction, "sh -c \"%s -XvQt /Volumes/%s/System/Library/Extensions/%s.kext/Contents/MacOS/%s\"", 
		t1, t2, kextName, kextName);
	sprintf(path, "/Volumes/%s/System/Library/Extensions/%s.kext/Contents/MacOS/%s", 
		partitionName, kextName, kextName);
	if ((otoolResult = popen(instruction, "r")) == NULL) {
		fprintf(stderr,"error!/n");  
    	return ; 
	}
	if ((kextFile = fopen(path, "r")) == NULL) {
		fprintf(stderr,"error!/n");  
    	return ; 
	}
	processData(otoolResult, kextFile);
}

void processData(FILE* otoolResult, FILE* kextFile) {
	int flag, i, j, k, addr, offset, ports;
	char data[255], info[17] = "Info10createInfo";
	char name[255], addrString[7], portString[3], offsetString[9], fbString[255], fb[10][40];
	while (fgets(data, 255, otoolResult)) {
		if (!hasPrefix(data, "__ZN")) continue; // has prefix "__ZN"
		
		flag = 0;
		for (i = 0; i < strlen(data); i++) { // contains "Info10createInfo"
			if (data[i] != info[0]) continue;
			j = i + 1;
			while (j < strlen(data) && j - i < 17 && data[j] == info[j - i])
				j++;
			if (j - i == 16) {
				flag = 1; break;
			}
		}
		if (!flag) continue;

		// get framebuffer name
		j = 4;
		while (data[j] >= '0' && data[j] <= '9') 
			j++;
		for (k = j; k < i; k++) 
			name[k - j] = data[k];
		name[k- j] = '\0';
		
		ports = -1;
		while (fgets(data, 255, otoolResult)) {
			flag = 0;
			if (hasPrefix(data, "ret")) break; // does not have prefix "ret"
			
			if (hasPrefix(data, "leaq")) {
				j = 0;
				while (data[j] != '(') 
					j++;
				for (i = j - 6; i > 0 && i < j; i++)
					addrString[i - j + 6] = data[i];
				addrString[6] = '\0';
				addr = hexdec(addrString);
			}

			if (ports == -1 && hasPrefix(data, "movb")) {
				i = 0;
				while (i < strlen(data) && data[i] != '$') 
					i++;
				if (i == strlen(data)) continue;
				if (data[i + 1] == '0' && data[i + 2] == 'x')
					i += 3;
				else continue;
				j = ++i;
				while (data[j] != ',')
					j++;
				for (k = i; k < j; k++)
					portString[k - i] = data[k];
				portString[k - i] = '\0';
				ports = hexdec(portString);
			}

			if (hasPrefix(data, "jl")) {
				for (i = strlen(data) - 9; i < strlen(data); i++)
					offsetString[i - strlen(data) + 9] = data[i];
				offsetString[8] = '\0';
				offset = hexdec(offsetString);
			}

			if (hasPrefix(data, "jmp")) {
				for (i = strlen(data) - 9; i < strlen(data); i++)
					offsetString[i - strlen(data) + 9] = data[i];
				offsetString[8] = '\0';
				offset = hexdec(offsetString) + 0x1A;
			}
		}

		addr += offset;
		printf("%s (%d) @ 0x%x\n", name, ports, addr);
		fseek(kextFile, addr, SEEK_SET);
		memset(fbString, 0, sizeof(fbString));
		memset(fb, 0, sizeof(fb));
		fread(fbString, 1, 16 * ports, kextFile);
		for (i = 0; i < ports; i++) {
			for (j = 0; j < 16; j++) {
				k = (int) fbString[i * 16 + j];
				if (((k & 0x00F0) >> 4) < 10){
					fb[i][2 * j] = ((k & 0x00F0) >> 4) + '0';
				}
				else {
					fb[i][2 * j] = ((k & 0x00F0) >> 4) - 10 + 'a';
				}
				if ((k & 0x000F) < 10){
					fb[i][2 * j + 1] = (k & 0x000F) + '0';
				}
				else {
					fb[i][2 * j + 1] = (k & 0x000F) - 10 + 'a';
				}
			}
		}
		for (i = 0; i < ports; i++) {
			if (i > 0) printf(", ");
			flag = 1;
			for (j = 0; j < 7; j++)
				if (hasPrefix(fb[i], value[j])){
					printf("%s", type[j]); flag = 0; break;
				}
			if (flag)
				printf("????");
		}
		printf("\n");
		for (i = 0; i < ports; i++) {
			printf("%s\n", fb[i]);
		}
		printf("\n");
	}
	fclose(kextFile);
	pclose(otoolResult);
}