package @@PACKAGE@@.web;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record Create@@ENTITY@@Request(@NotBlank @Size(max = 255) String name) {
}
