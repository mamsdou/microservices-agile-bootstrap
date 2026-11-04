package @@PACKAGE@@.web;

import @@PACKAGE@@.service.@@ENTITY@@Service;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/@@RESOURCE@@")
public class @@ENTITY@@Controller {

    private final @@ENTITY@@Service service;

    public @@ENTITY@@Controller(@@ENTITY@@Service service) {
        this.service = service;
    }

    @GetMapping
    public List<@@ENTITY@@Response> list() {
        return service.findAll().stream().map(@@ENTITY@@Response::from).toList();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public @@ENTITY@@Response create(@Valid @RequestBody Create@@ENTITY@@Request request) {
        return @@ENTITY@@Response.from(service.create(request.name()));
    }
}
