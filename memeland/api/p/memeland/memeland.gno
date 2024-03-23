package memeland

import (
	"std"
	"strconv"
	"strings"
	"time"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/seqid"
)

type Post struct {
	ID            string
	Data          string
	Author        std.Address
	Timestamp     time.Time
	UpvoteTracker *avl.Tree // address > struct{}{}
}

type Memeland struct {
	Posts       []*Post
	MemeCounter seqid.ID
}

// NewMemeland returns a pointer to a new Memeland object
// Initializes all the subfields
func NewMemeland() *Memeland {
	panic("implement me")
}

// PostMeme - Adds a new post at timestamp, with data
// Panics in case data is empty or timestamp is invalid
// Returns the ID of the created Post
func (m *Memeland) PostMeme(data string, timestamp int64) string {
	if data == "" || timestamp <= 0 {
		panic("invalid data or timestamp")
	}

	id := m.MemeCounter.Next().String()
	newPost := &Post{
		ID:            id,
		Data:          data,
		Author: 			 std.PrevRealm().Addr(),
		Timestamp:     time.Unix(timestamp, 0),
		UpvoteTracker: avl.NewTree(),
	}

	m.Posts = append(m.Posts, newPost)
	return id
}

// Upvote increases the upvote count of a specific Post
// Panics if specified ID doesn't exist, or the user has already upvoted
func (m *Memeland) Upvote(id string) string {
	post := m.getPost(id)
	if post == nil {
		panic("post not found")
	}

	caller := std.PrevRealm().Addr().String()

	if _, exists := post.UpvoteTracker.Get(caller); exists {
		panic("user has already upvoted")
	}

	post.UpvoteTracker.Set(caller, struct{}{})
	return "upvote successful"
}

// GetPostsInRange returns a JSON object containing marshalled Posts in a specific timestamp range
// Timestamps are given as Unix seconds
// Supports pagination
// sortBy can be "UPVOTES" (most upvotes-first), or "DATE_CREATED" (newest-first)
// Panics if page < 1, pageSize < 1, or pageSize > 10
// Returns empty JSON object if there are no posts in the specified range.
func (m *Memeland) GetPostsInRange(startTimestamp, endTimestamp int64, page, pageSize int, sortBy string) string {
	if len(m.Posts) == 0 {
		return "[]"
	}
	if (page < 1) || (pageSize < 1) || (pageSize > 10) {
		panic("invalid page or pageSize")
	}

	var filteredPosts []*Post

	start := time.Unix(startTimestamp, 0)
	end := time.Unix(endTimestamp, 0)

	for _, p := range m.Posts {
		if p.Timestamp.After(start) && p.Timestamp.Before(end) {
			filteredPosts = append(filteredPosts, p)
		}
	}

	switch sortBy {
		case "UPVOTES":
			std.SortSlice(filteredPosts, func(i, j int) bool {
				return filteredPosts[i].UpvoteTracker.Size() > filteredPosts[j].UpvoteTracker.Size()
			})
		case "DATE_CREATED":
			std.SortSlice(filteredPosts, func(i, j int) bool {
				return filteredPosts[i].Timestamp.After(filteredPosts[j].Timestamp)
			})
	}

	startIndex := (page - 1) * pageSize
	endIndex := std.MinInt(startIndex + pageSize, len(filteredPosts))

	return PostsToJSONString(filteredPosts[startIndex:endIndex])
}

// getPost gets a post by ID
func (m *Memeland) getPost(id string) *Post {
	panic("implement me")
}

// PostsToJSONString converts a slice of Post structs into a JSON string
func PostsToJSONString(posts []*Post) string {
	var sb strings.Builder
	sb.WriteString("[")

	for i, post := range posts {
		if i > 0 {
			sb.WriteString(",")
		}

		sb.WriteString(PostToJSONString(post))
	}
	sb.WriteString("]")

	return sb.String()
}

// PostToJSONString returns a Post formatted as a JSON string
// Note: Gno currently does not support reflection, which is why JSON marshalling is unavailable
func PostToJSONString(post *Post) string {
	var sb strings.Builder

	sb.WriteString("{")
	sb.WriteString(`"id":"` + post.ID + `",`)
	sb.WriteString(`"data":"` + escapeString(post.Data) + `",`)
	sb.WriteString(`"author":"` + escapeString(post.Author.String()) + `",`)
	sb.WriteString(`"timestamp":"` + strconv.Itoa(int(post.Timestamp.Unix())) + `",`)
	sb.WriteString(`"upvotes":` + strconv.Itoa(post.UpvoteTracker.Size()))
	sb.WriteString("}")

	return sb.String()
}

// escapeString escapes quotes in a string for JSON compatibility.
func escapeString(s string) string {
	return strings.ReplaceAll(s, `"`, `\"`)
}
