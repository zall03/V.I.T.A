package users

type CreateDTO struct {
	Email           string  `json:"email" validate:"required,email,max=254"`
	Name            string  `json:"name" validate:"required,min=1,max=120"`
	Password        string  `json:"password" validate:"required,min=12,max=128"`
	Role            string  `json:"role" validate:"required,oneof=nurse queue_operator"`
	PractitionerIHS *string `json:"practitioner_ihs" validate:"omitempty,max=100"`
}
type UpdateDTO struct {
	Email           string  `json:"email" validate:"required,email,max=254"`
	Name            string  `json:"name" validate:"required,min=1,max=120"`
	Role            string  `json:"role" validate:"required,oneof=nurse queue_operator"`
	PractitionerIHS *string `json:"practitioner_ihs" validate:"omitempty,max=100"`
}
type ActiveDTO struct {
	Active *bool `json:"active" validate:"required"`
}
