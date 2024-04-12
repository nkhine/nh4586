package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"time"
)

// Define a struct to match the JSON response structure
type ApiResponse struct {
	Count    int    `json:"count"`
	Next     int    `json:"next"`
	Previous int    `json:"previous"`
	Items    []Item `json:"items"`
}

type Item struct {
	SFID         string       `json:"sfid"`
	Title        string       `json:"title"`
	Room         Room         `json:"room"`
	FromDate     string       `json:"from_date"`
	ToDate       string       `json:"to_date"`
	Type         string       `json:"type"`
	Practitioner Practitioner `json:"practitioner"`
	Product      Product      `json:"product"`
	MyBooking    MyBooking    `json:"my_booking"`
}

type Room struct {
	SFID     string   `json:"sfid"`
	Name     string   `json:"name"`
	Facility Facility `json:"facility"`
}

type Facility struct {
	SFID string `json:"sfid"`
	Name string `json:"name"`
}

type Practitioner struct {
	SFID string `json:"sfid"`
	Name string `json:"name"`
}

type Product struct {
	SFID string `json:"sfid"`
	Name string `json:"name"`
}

type MyBooking struct {
	SFID   string `json:"sfid"`
	Status string `json:"status"`
}

func fetchItems(page int) (*ApiResponse, error) {
	bearerToken := os.Getenv("NUFFIELD_BEARER_TOKEN")
	subscriptionKey := "882ee8ab406042dd9da8045dc58874a3"

	client := &http.Client{}
	req, err := http.NewRequest("GET", fmt.Sprintf("https://api.nuffieldhealth.com/booking/member/1.0/bookings/?past=true&page=%d", page), nil)
	if err != nil {
		return nil, err
	}

	req.Header.Add("Authorization", "Bearer "+bearerToken)
	req.Header.Add("Ocp-Apim-Subscription-Key", subscriptionKey)
	req.Header.Add("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var apiResponse ApiResponse
	if err := json.Unmarshal(body, &apiResponse); err != nil {
		return nil, err
	}

	return &apiResponse, nil
}

type sortableItems []Item

func (s sortableItems) Len() int {
	return len(s)
}

func (s sortableItems) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

// func (s sortableItems) Less(i, j int) bool {
// 	t1, _ := time.Parse(time.RFC3339, s[i].FromDate)
// 	t2, _ := time.Parse(time.RFC3339, s[j].FromDate)
// 	return t1.After(t2) // Sort by descending order
// }

func (s sortableItems) Less(i, j int) bool {
	t1, _ := time.Parse(time.RFC3339, s[i].FromDate)
	t2, _ := time.Parse(time.RFC3339, s[j].FromDate)
	return t1.Before(t2) // Sort by ascending order
}

func main() {
	file, err := os.Create("output.csv")
	if err != nil {
		fmt.Println("Error creating CSV file:", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write CSV header
	writer.Write([]string{"Type", "From Date", "To Date", "Practitioner Name", "Practitioner SFID", "Product Name", "Product SFID", "Booking Status"})

	var allItems sortableItems

	page := 1
	for {
		response, err := fetchItems(page)
		if err != nil {
			fmt.Printf("Error fetching page %d: %v\n", page, err)
			break
		}

		for _, item := range response.Items {
			if item.MyBooking.Status == "User Cancelled" {
				continue // Skip the entry
			}
			allItems = append(allItems, item)
		}

		if response.Next == 0 {
			break
		}
		page = response.Next
	}

	sort.Sort(allItems) // Sort items

	// Write sorted data to CSV
	for _, item := range allItems {
		writer.Write([]string{
			item.Type,
			item.FromDate,
			item.ToDate,
			item.Practitioner.Name,
			item.Practitioner.SFID,
			item.Product.Name,
			item.Product.SFID,
			item.MyBooking.Status,
		})
	}
}
