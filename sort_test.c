#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void bubble_sort(int arr[], int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                int temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

void quick_sort(int arr[], int low, int high) {
    if (low < high) {
        int pivot = arr[high];
        int i = low - 1;
        for (int j = low; j < high; j++) {
            if (arr[j] <= pivot) {
                i++;
                int temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
        }
        int temp = arr[i + 1];
        arr[i + 1] = arr[high];
        arr[high] = temp;

        quick_sort(arr, low, i);
        quick_sort(arr, i + 2, high);
    }
}

void print_array(int arr[], int n) {
    for (int i = 0; i < n; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
}

int main() {
    int arr1[] = {64, 34, 25, 12, 22, 11, 90};
    int n1 = sizeof(arr1) / sizeof(arr1[0]);

    int arr2[] = {64, 34, 25, 12, 22, 11, 90};
    int n2 = n1;

    printf("Original array: ");
    print_array(arr1, n1);

    // Bubble Sort
    bubble_sort(arr1, n1);
    printf("Bubble sort:   ");
    print_array(arr1, n1);

    // Quick Sort
    quick_sort(arr2, 0, n2 - 1);
    printf("Quick sort:    ");
    print_array(arr2, n2);

    // Verify both are sorted correctly
    int sorted = 1;
    for (int i = 1; i < n1; i++) {
        if (arr1[i] < arr1[i - 1]) sorted = 0;
    }
    printf("\nVerification: %s\n", sorted ? "PASSED" : "FAILED");

    return 0;
}
